package game
{
    import com.nodename.delaunay.Voronoi;
    import com.nodename.geom.*;

    import events.StateEvent;

    import flash.events.Event;

    import flash.events.EventDispatcher;

    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import game.controllers.Tectonics;

    import game.graph.*;
    import game.task.Task;
    import game.task.TaskId;

    import global.Rand;
    import global.Util;

    import managers.State;

    import mx.collections.ArrayCollection;
    import mx.events.CollectionEvent;

    import ui.components.Canvas;

    public class Map extends EventDispatcher
    {
        private static var _instance:Map;

        public var canvas:Canvas;

        public var layers:ArrayCollection = new ArrayCollection();
        public var layersById:Object = {};
        public var loaded:Boolean = false;
        public var invalidatedOperations:Object = {};

        private var bounds:Rectangle;

        // Model
        public var points:Vector.<Point>;
        public var cells:Vector.<Cell>;
        public var corners:Vector.<Corner>;
        public var edges:Vector.<Edge>;

        // Point Mapping
        public var cellsByPoints:Object;
        private var quad:QuadTree;

        // Layers and Operations
        private var defaultLayerOrder:Array = [Layer.POINTS, Layer.VORONOI, Layer.DELAUNAY, Layer.TECTONIC_PLATES];
        private var operations:Array = ["points", "plates"];

        public function Map(canvas:Canvas)
        {
            if (_instance)
                throw new Error("Singletons can only have one instance");
            _instance = this;

            this.canvas = canvas;

            defaultLayerOrder.reverse();

            var arr:Array = State.read("layers");
            var layer:Layer;
            if (arr)
            {
                // Custom layer order
                for each(var l:Object in arr)
                {
                    layer = new Layer();
                    layer.id = l.id;
                    layer.visible = l.visible;
                    layersById[l.id] = layer;
                    layers.addItem(layer);
                }
            } else
            {
                // Default layer order
                for each (var id:String in defaultLayerOrder)
                {
                    layer = new Layer();
                    layer.id = id;
                    layer.visible = true;
                    layersById[id] = layer;
                    layers.addItem(layer);
                }
            }

            State.dispatcher.addEventListener(State.STATE_CHANGED, onStateChanged);
            layers.addEventListener(CollectionEvent.COLLECTION_CHANGE, onLayersChange);
        }

        public function getCellbyPoint(p:Point):Cell
        {
            return cellsByPoints[JSON.stringify(p)];
        }

        public function getClosestPoint(p:Point):Point
        {
            if (!quad)
                return null;

            // Only return a point within a small radius
            var arr:Vector.<Point> = quad.queryFromPoint(p, 10);
            if (arr.length == 0)
                return null;
            if (arr.length == 1)
                return arr[0];

            var closest:Point = arr[0];
            var distance:Number = Number.POSITIVE_INFINITY;
            for each (var q:Point in arr)
            {
                var d:Number = Point.distance(p, q);
                if (d < distance)
                {
                    closest = q;
                    distance = d;
                }
            }

            return closest;
        }

        private function onStateChanged(event:StateEvent):void
        {
            var operation:String = event.id.split(".")[0];
            if (operations.indexOf(operation) >= 0)
                invalidatedOperations[operation] = true;

            if (event.id == "layers")
                canvas.validateLayersOrderAndVisibility();
        }

        public function loadPreviousTasks(taskId:String):void
        {
            // Load data from save file instead of calculating it for
            // all tasks with a lower index than the current task

            trace("loadPreviousTasks: " + taskId);
            var currentTask:Task = Task.byId(taskId);
            for (var i:int = 0; i < currentTask.index; i++)
            {
                var t:Task = Task.byIndex(i);
                trace("  -" + t.id);
                switch (t.id)
                {
                    case TaskId.READ_INTRODUCTION:
                        break;
                    case TaskId.MAKE_VORONOI_POINTS:
                        // Load points and make Voronoi graph
                        loadPoints();
                        makeVoronoiGraph();
                        Tectonics.loadPlates();
                        break;
                    case TaskId.MAKE_TECTONIC_PLATES:
                        break;
                    default:
                        break;
                }
            }

            // Invalidate operations belonging to the current task
            for each (var operation:String in currentTask.operations)
                invalidatedOperations[operation] = true;

            loaded = true;
            dispatchEvent(new Event(Event.COMPLETE));
        }

        private function loadPoints():void
        {
            if (points != null)
                return;

            bounds = new Rectangle(0,
                    0,
                    2000,
                    1000);

            points = new Vector.<Point>();
            quad = new QuadTree(bounds);
            var arr:Array = State.read("points.points");
            trace("Adding " + arr.length + " points");
            for each (var u:Object in arr)
                addPoint(new Point(u.x, u.y));
        }

        public function calculate():void
        {
            trace("@calculate, " + JSON.stringify(invalidatedOperations));

            // Loop through all invalidated operations and calculate them
            for (var operation:String in invalidatedOperations)
            {
                switch (operation)
                {
                    case "points":
                        // Make points and the voronoi graph
                        makePoints();
                        makeVoronoiGraph();
                        break;
                    case "plates":
                        // Fill tectonics from their origins
                        Tectonics.calculate();
                        break;
                    default:
                        break;
                }
            }

            invalidatedOperations = {};

            // Draw all layers
            Artist.draw();
            Artist.drawUI();

            canvas.validateLayersOrderAndVisibility();
        }

        public function resetLayers():void
        {
            for (var i:int = 0; i < defaultLayerOrder.length; i++)
            {
                var id:String = defaultLayerOrder[i];
                for (var j:int = 0; j < layers.length; j++)
                {
                    var l:Layer = layers[j];
                    if (l.id != id)
                        continue;

                    l.visible = true;
                    layers.addItemAt(layers.removeItemAt(j), i);
                }
            }
        }

        private function onLayersChange(event:CollectionEvent):void
        {
            var arr:Array = [];
            for each (var layer:Layer in layers)
                arr.push({
                    id: layer.id,
                    visible: layer.visible
                });

            State.write("layers", arr);
        }

        public function validateAllowedLayers():void
        {
            for each (var layer:Layer in layers)
            {
                var b:Boolean = Task.current.layers.indexOf(layer.id) >= 0;
                if (layer.allowed != b)
                {
                    layer.allowed = b;
                    layers.itemUpdated(layer);
                }
            }
        }

        private function makePoints():void
        {
            bounds = new Rectangle(0,
                    0,
                    2000,
                    1000);

            points = new Vector.<Point>();
            quad = new QuadTree(bounds);

            var type:String = State.read("points.type");
            switch (type)
            {
                case "poissonDisc":
                    makePoissonDiscPoints();
                    break;
                case "square":
                    makeSquareGridPoints();
                    break;
                case "hex":
                    makeHexGridPoints();
                    break;
                case "random":
                    makeRandomPoints();
                    break;
            }

            var simplePoints:Array = [];
            for each (var p:Point in points)
                simplePoints.push({x: p.x, y: p.y});

            State.write("points.points", simplePoints, false);
        }

        public function addPoint(p:Point):void
        {
            p.x = Util.fixed(p.x, 2);
            p.y = Util.fixed(p.y, 2);

            points.push(p);
            quad.insert(p);
        }

        private function makePoissonDiscPoints():void
        {
            var rand:Rand = new Rand(Util.stringToSeed(State.read("points.seed")));
            var spacing:int = State.read("points.spacing");
            var precision:int = State.read("points.precision");

            // The active point queue
            var queue:Vector.<Point> = new Vector.<Point>();

            var point:Point = new Point(int(bounds.width / 2),
                    int(bounds.height / 2));

            var doubleSpacing:Number = spacing * 2;
            var doublePI:Number = 2 * Math.PI;

            var box:Rectangle = new Rectangle(0,
                    0,
                    2 * spacing,
                    2 * spacing);

            // Make border points
            var gap:int = spacing;
            for (var i:int = gap; i < bounds.width; i += 2 * gap)
            {
                addPoint(new Point(i, gap));
                addPoint(new Point(i, bounds.height - gap));
            }

            for (i = 2 * gap; i < bounds.height - gap; i += 2 * gap)
            {
                addPoint(new Point(gap, i));
                addPoint(new Point(bounds.width - gap, i));
            }

            // Initial point
            addPoint(point);
            queue.push(point);

            var candidate:Point = null;
            var angle:Number;
            var distance:int;

            while (queue.length > 0)
            {
                point = queue[0];

                for (i = 0; i < precision; i++)
                {
                    angle = rand.next() * doublePI;
                    distance = rand.between(spacing, doubleSpacing);

                    candidate = new Point(point.x + distance * Math.cos(angle),
                            point.y + distance * Math.sin(angle));

                    // Check point distance to nearby points
                    box.x = candidate.x - spacing;
                    box.y = candidate.y - spacing;
                    if (quad.isRangePopulated(box))
                    {
                        candidate = null;
                    } else
                    {
                        // Valid candidate
                        if (!bounds.contains(candidate.x, candidate.y))
                        {
                            // Candidate is outside the area, so don't include it
                            candidate = null;
                            continue;
                        }
                        break;
                    }
                }

                if (candidate)
                {
                    addPoint(candidate);
                    queue.push(candidate);
                } else
                {
                    // Remove the first point in queue
                    queue.shift();
                }
            }
        }

        private function makeSquareGridPoints():void
        {
            var spacing:int = State.read("points.spacing");

            for (var i:int = spacing; i < bounds.width; i += spacing)
                for (var j:int = spacing; j < bounds.height; j += spacing)
                    addPoint(new Point(i, j));
        }

        private function makeHexGridPoints():void
        {
            var spacing:int = State.read("points.spacing");

            var verticalSpacing:Number = Math.sqrt(Math.pow(spacing, 2) - Math.pow(spacing / 2, 2));
            var n:int = 0;
            for (var i:int = verticalSpacing; i < bounds.height; i += verticalSpacing)
            {
                var j:int = spacing;
                if (n % 2 == 0)
                    j += spacing / 2;
                for (j; j < bounds.width; j += spacing)
                    addPoint(new Point(j, i));

                n++;
            }
        }

        private function makeRandomPoints():void
        {
            var rand:Rand = new Rand(Util.stringToSeed(State.read("points.seed")));
            var amount:int = State.read("points.amount");
            for (var i:int = 0; i < amount; i++)
            {
                // Add a random point
                var p:Point = new Point(int(rand.between(0, bounds.width)), int(rand.between(0, bounds.height)));
                addPoint(p);
            }
        }

        private function makeVoronoiGraph():void
        {
            var voronoi:Voronoi = new Voronoi(points, bounds);

            cells = new Vector.<Cell>();
            corners = new Vector.<Corner>();
            edges = new Vector.<Edge>();

            // Make cell dictionary
            var cellsDictionary:Dictionary = new Dictionary();
            for each (var point:Point in points)
            {
                var cell:Cell = new Cell();
                cell.index = cells.length;
                cell.point = point;
                cells.push(cell);
                cellsDictionary[point] = cell;
            }

            for each (cell in cells)
                voronoi.region(cell.point);

            /**
             * Associative Mapping
             */

            cellsByPoints = {};
            for each (cell in cells)
                cellsByPoints[JSON.stringify(cell.point)] = cell;

            /**
             * Corners
             */

            var _cornerMap:Array = [];

            function makeCorner(point:Point):Corner
            {
                if (!point)
                {
                    return null;
                }
                for (var bucket:int = point.x - 1; bucket <= point.x + 1; bucket++)
                {
                    for each (var corner:Corner in _cornerMap[bucket])
                    {
                        var dx:Number = point.x - corner.point.x;
                        var dy:Number = point.y - corner.point.y;
                        if (dx * dx + dy * dy < 1e-6)
                        {
                            return corner;
                        }
                    }
                }

                bucket = int(point.x);

                if (!_cornerMap[bucket])
                {
                    _cornerMap[bucket] = [];
                }

                corner = new Corner();
                corner.index = corners.length;
                corners.push(corner);

                corner.point = point;
                corner.border = (point.x == 0 || point.x == bounds.width || point.y == 0 || point.y == bounds.height);

                _cornerMap[bucket].push(corner);
                return corner;
            }

            /**
             * Edges
             */

            var libEdges:Vector.<com.nodename.delaunay.Edge> = voronoi.edges();
            for each (var libEdge:com.nodename.delaunay.Edge in libEdges)
            {
                var dEdge:Segment = libEdge.delaunayLine();
                var vEdge:Segment = libEdge.voronoiEdge();

                var edge:Edge = new Edge();
                edge.index = edges.length;
                edges.push(edge);
                edge.midpoint = vEdge.p0 && vEdge.p1 && Point.interpolate(vEdge.p0,
                        vEdge.p1,
                        0.5);

                edge.v0 = makeCorner(vEdge.p0);
                edge.v1 = makeCorner(vEdge.p1);
                edge.d0 = cellsDictionary[dEdge.p0];
                edge.d1 = cellsDictionary[dEdge.p1];

                setupEdge(edge);
            }

            for each (cell in cells)
                cell.calculateArea();
        }

        private function setupEdge(edge:Edge):void
        {
            if (edge.d0 != null)
                edge.d0.edges.push(edge);

            if (edge.d1 != null)
                edge.d1.edges.push(edge);

            if (edge.v0 != null)
                edge.v0.protrudes.push(edge);

            if (edge.v1 != null)
                edge.v1.protrudes.push(edge);

            if (edge.d0 != null && edge.d1 != null)
            {
                addToCellList(edge.d0.neighbors,
                        edge.d1);
                addToCellList(edge.d1.neighbors,
                        edge.d0);
            }

            if (edge.v0 != null && edge.v1 != null)
            {
                addToCornerList(edge.v0.adjacent,
                        edge.v1);
                addToCornerList(edge.v1.adjacent,
                        edge.v0);
            }

            if (edge.d0 != null)
            {
                addToCornerList(edge.d0.corners,
                        edge.v0);
                addToCornerList(edge.d0.corners,
                        edge.v1);
            }

            if (edge.d1 != null)
            {
                addToCornerList(edge.d1.corners,
                        edge.v0);
                addToCornerList(edge.d1.corners,
                        edge.v1);
            }

            if (edge.v0 != null)
            {
                addToCellList(edge.v0.touches,
                        edge.d0);
                addToCellList(edge.v0.touches,
                        edge.d1);
            }

            if (edge.v1 != null)
            {
                addToCellList(edge.v1.touches,
                        edge.d0);
                addToCellList(edge.v1.touches,
                        edge.d1);
            }

            function addToCornerList(v:Vector.<Corner>,
                                     x:Corner):void
            {
                if (x != null && v.indexOf(x) < 0)
                {
                    v.push(x);
                }
            }

            function addToCellList(v:Vector.<Cell>,
                                   x:Cell):void
            {
                if (x != null && v.indexOf(x) < 0)
                {
                    v.push(x);
                }
            }
        }

        public static function get instance():Map
        {
            if (!_instance)
                new Map(null);
            return _instance;
        }
    }
}