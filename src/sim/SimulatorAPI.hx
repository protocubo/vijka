package sim;

import elebeta.ett.vijka.*;
import format.ett.Data.Encoding in ETTEncoding;
import format.ett.Data.Field in ETTField;
import format.ett.Reader;
import format.ett.Writer;
import haxe.io.Eof;
import haxe.io.StringInput;
import sim.Algorithm;
import sim.col.LinkTypeSpeedMap;
import sim.uq.Search;
import sim.uq.Update;
import sys.FileSystem;
import sys.io.FileInput;
import sys.io.FileOutput;
import tools.NetworkCompressor;
import tools.Ogr2Ogr;
import tools.Splitter;

import jonas.NumberPrinter.printDecimal;
import Lambda.array;
import Lambda.count;
import Lambda.filter;
import Lambda.has;
import Lambda.list;
import sim.Simulator.baseNewline;
import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;
import sim.Simulator.printr;
import sim.Simulator.printrln;
import sim.Simulator.tabs;
import Std.parseFloat;
import Std.parseInt;
import Std.string;

using sim.SimulatorStateTools;
using sim.data.LinkTools;

class SimulatorAPI extends mcli.CommandLine {

	private var reading:Bool;
	private var sim:Simulator;
	private var state(get,never):SimulatorState;
	private function get_state() return sim.state;

	private var _stop:Bool;

	public function new( _sim:Simulator, _reading:Bool ) {
		sim = _sim;
		reading = _reading;
		super();
	}



	// NODE I/O -----------------------------------------------------------------

	/**
		Read nodes from Node ETT in `path` (reentrant)
	**/
	public function readNodes( path:String ) {
		if ( sim.state.nodes == null ) {
			println( "Reading nodes" );
			sim.state.nodes = new Map();
		}
		else {
			println( "Reading additional nodes" );
			println( "Existing nodes may have been changed, consider verifying link shapes" );
		}
		var nodes = sim.state.nodes; // just a shortcut
		var einp = _readEtt( path );
		sim.state.invalidate();
		while ( true ) {
			var node = try { einp.fastReadRecord( Node.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( node == null ) break;
			nodes.set( node.id, node );
		}
		einp.close();
	}

	/**
		Search nodes with optional `filter` expression and output `type`;
		`type` can be "show", "head" or "count" (default)
	**/
	public function queryNodes( ?filter="true==true", ?type="count" ) {
		var q = Search.prepare( filter, "id" );
		_genericQuery( q, sim.state.nodes, null, type
		, "Searching for nodes matching '"+filter+"'", "No nodes" );
	}

	/**
		Write nodes to Node ETT in `path`, using optional `filter`; will
		overwrite existing files
	**/
	public function ettNodes( path:String, ?filter:String ) {
		var nodes:Iterable<Node> = sim.state.nodes;
		if ( filter != null ) {
			var q = Search.prepare( filter, "id" );
			nodes = q.execute( sim, sim.state.nodes, null );
		}
		return _genericEtt( path, nodes, Node, "Writing nodes", "No nodes" );
	}

	/**
		Write nodes to GeoJSON in `path`, using optional `filter`
	**/
	public function geojsonNodes( path:String, ?filter:String ) {
		println( "Mapping nodes in GeoJSON" );
		var nodes = sim.state.nodes; // just a shortcut
		if ( nodes == null ) throw "No nodes";
		var fout = _writeFile( path, false );
		fout.writeString( '{"type":"FeatureCollection","features":['+sim.state.newline );
		var first = true;
		if ( filter == null ) {
			for ( n in nodes ) {
				if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
				fout.writeString( _geojsonNode( n ) );
			}
		}
		else {
			var q = Search.prepare( filter, "id" );
			for ( n in q.execute( sim, nodes, null ) ) {
				if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
				fout.writeString( _geojsonNode( n ) );
			}
		}
		fout.writeString( sim.state.newline+"] }"+sim.state.newline );
		fout.close();
	}

	/**
		Write nodes to Shapefile set preffixed by `path`, using optional `filter`
	**/
	public function shpNodes( path:String, ?filter:String ) {
		println( "Mapping nodes in ESRI Shapefile" );
		_shp( geojsonNodes, path, filter );
	}



	// LINK TYPE I/O ------------------------------------------------------------

	/**
		Read link types from LinkType ETT in `path` (reentrant)
	**/
	public function readTypes( path:String ) {
		if ( sim.state.linkTypes == null ) {
			println( "Reading link types" );
			sim.state.linkTypes = new Map();
		}
		else {
			println( "Reading additional link types" );
		}
		var linkTypes = sim.state.linkTypes; // just a shortcut
		var einp = _readEtt( path );
		while ( true ) {
			var type = try { einp.fastReadRecord( LinkType.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( type == null ) break;
			linkTypes.set( type.id, type );
		}
		einp.close();
	}

	/**
		Search link types with optional `filter` expression and output `type`;
		`type` can be "show", "head" or "count" (default)
	**/
	public function queryTypes( ?filter="true==true", ?type="count" ) {
		var q = Search.prepare( filter, "id" );
		_genericQuery( q, sim.state.linkTypes, null, type
		, "Searching for link types matching '"+filter+"'", "No link types" );
	}

	/**
		Write link types to LinkType ETT in `path`, using optional `filter`; will
		overwrite existing files
	**/
	public function ettTypes( path:String, ?filter:String ) {
		var linkTypes:Iterable<LinkType> = sim.state.linkTypes;
		if ( filter != null ) {
			var q = Search.prepare( filter, "id" );
			linkTypes = q.execute( sim, sim.state.linkTypes, null );
		}
		return _genericEtt( path, linkTypes, LinkType, "Writing link types", "No link types" );
	}



	// LINK I/O -----------------------------------------------------------------

	/**
		Read links from Link ETT in `path` (reentrant); requires nodes and link
		types; extensions should be in km
	**/
	public function readLinks( path:String ) {
		if ( sim.state.links == null ) {
			println( "Reading links" );
			sim.state.links = new Map();
		}
		else {
			println( "Reading additional links" );
		}
		var nodes = sim.state.nodes; // just a shortcut
		var links = sim.state.links; // just a shortcut
		var linkTypes = sim.state.linkTypes; // just a shortcut
		if ( nodes == null ) throw "No nodes";
		if ( linkTypes == null ) throw "No link types";
		var einp = _readEtt( path );
		sim.state.invalidate();
		while ( true ) {
			var link = try { einp.fastReadRecord( Link.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( link == null ) break;
			if ( !nodes.exists( link.startNodeId ) )
				throw "Missing node "+link.startNodeId;
			if ( !nodes.exists( link.finishNodeId ) )
				throw "Missing node "+link.finishNodeId;
			if ( !linkTypes.exists( link.typeId ) )
				throw "Missing link type "+link.typeId;
			links.set( link.id, link );
		}
		einp.close();
	}

	/**
		Search links with optional `filter` expression and output `type`;
		`type` can be "show", "head" or "count" (default)
	**/
	public function queryLinks( ?filter="true==true", ?type="count" ) {
		var q = Search.prepare( filter, "id" );
		_genericQuery( q, sim.state.links, sim.state.aliases, type
		, "Searching for links matching '"+filter+"'", "No links" );
	}

	/**
		Write links to Link ETT in `path`, using optional `filter`; will overwrite
		existing files
	**/
	public function ettLinks( path:String, ?filter:String ) {
		var links:Iterable<Link> = sim.state.links;
		if ( filter != null ) {
			var q = Search.prepare( filter, "id" );
			links = q.execute( sim, sim.state.links, sim.state.aliases );
		}
		return _genericEtt( path, links, Link, "Writing links", "No links" );
	}

	/**
		Write links to GeoJSON in `path` using available link shape data; accepts
		(optionnally) a unified `filter` query; will overwrite existing files
	**/
	public function geojsonLinks( path:String, ?filter:String ) {
		println( "Mapping links in GeoJSON" );
		var links = sim.state.links; // just a shortcut
		if ( links == null ) throw "No links";
		var fout = _writeFile( path, false );
		fout.writeString( '{"type":"FeatureCollection","features":['+sim.state.newline );
		var first = true;
		if ( filter == null ) {
			for ( k in links ) {
				if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
				fout.writeString( _geojsonLink( k, false, false ) );
			}
		}
		else {
			var aliases = sim.state.aliases;
			var q = Search.prepare( filter, "id" );
			for ( k in q.execute( sim, links, aliases ) ) {
				if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
				fout.writeString( _geojsonLink( k, false, false ) );
			}
		}
		fout.writeString( sim.state.newline+"] }"+sim.state.newline );
		fout.close();
	}

	/**
		Write links to Shapefile set preffixed by `path` using available link shape data; accepts
		(optionnally) a unified `filter` query; will overwrite existing files
	**/
	public function shpLinks( path:String, ?filter:String ) {
		println( "Mapping links in ESRI Shapefile" );
		_shp( geojsonLinks, path, filter );
	}

	/**
		Write links to GeoJSON in `path` using available link shape data and
		including speed information; accepts (optionnally) a unified `filter`
		query; will overwrite existing files
	**/
	public function geojsonLinkSpeeds( path:String, ?filter:String ) {
		println( "Mapping links in GeoJSON" );
		var links = sim.state.links; // just a shortcut
		if ( links == null ) throw "No links";
		var fout = _writeFile( path, false );
		fout.writeString( '{"type":"FeatureCollection","features":['+sim.state.newline );
		var first = true;
		if ( filter == null ) {
			for ( k in links ) {
				if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
				fout.writeString( _geojsonLink( k, true, false ) );
			}
		}
		else {
			var aliases = sim.state.aliases;
			var q = Search.prepare( filter, "id" );
			for ( k in q.execute( sim, links, aliases ) ) {
				if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
				fout.writeString( _geojsonLink( k, true, false ) );
			}
		}
		fout.writeString( sim.state.newline+"] }"+sim.state.newline );
		fout.close();
	}

	/**
		Write links to Shapefile set preffixed by `path` using available link shape data and
		including speed information; accepts (optionnally) a unified `filter`
		query; will overwrite existing files
	**/
	public function shpLinkSpeeds( path:String, ?filter:String ) {
		println( "Mapping links in ESRI Shapefile" );
		_shp( geojsonLinkSpeeds, path, filter );
	}

	/**
		Write links to GeoJSON in `path` using available link shape data and
		including travel time information; accepts (optionnally) a unified `filter`
		query; will overwrite existing files
	**/
	public function geojsonLinkTimes( path:String, ?filter:String ) {
		println( "Mapping links in GeoJSON" );
		var links = sim.state.links; // just a shortcut
		if ( links == null ) throw "No links";
		var fout = _writeFile( path, false );
		fout.writeString( '{"type":"FeatureCollection","features":['+sim.state.newline );
		var first = true;
		if ( filter == null ) {
			for ( k in links ) {
				if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
				fout.writeString( _geojsonLink( k, false, true ) );
			}
		}
		else {
			var aliases = sim.state.aliases;
			var q = Search.prepare( filter, "id" );
			for ( k in q.execute( sim, links, aliases ) ) {
				if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
				fout.writeString( _geojsonLink( k, false, true ) );
			}
		}
		fout.writeString( sim.state.newline+"] }"+sim.state.newline );
		fout.close();
	}

	/**
		Write links to Shapefile set preffixed by `path` using available link shape data and
		including travel time information; accepts (optionnally) a unified `filter`
		query; will overwrite existing files
	**/
	public function shpLinkTimes( path:String, ?filter:String ) {
		println( "Mapping links in ESRI Shapefile" );
		_shp( geojsonLinkTimes, path, filter );
	}



	// LINK SHAPE I/O -----------------------------------------------------------

	/**
		Read link shape from LinkShape ETT in `path` (reentrant); shapes for
		unknown links are just ignored
	**/
	public function readShapes( path:String ) {
		if ( sim.state.shapes == null ) {
			println( "Reading link shapes" );
			sim.state.shapes = new Map();
		}
		else {
			println( "Reading additional link shapes; overwriting when necessary" );
		}
		var links = sim.state.links; // just a shortcut
		if ( links == null || !links.iterator().hasNext() )
			return; // no links
		var shapes = sim.state.shapes; // just a shortcut
		var einp = _readEtt( path );
		while ( true ) {
			var shape = try { einp.fastReadRecord( LinkShape.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( shape == null ) break;
			if ( links.exists( shape.linkId ) )
				shapes.set( shape.linkId, shape );
		}
		einp.close();
	}

	/**
		Count links with custom shapes
	**/
	public function countShapes() {
		var cnt = sim.state.shapes != null ? count( sim.state.shapes ) : 0;
		println( "Counted "+cnt+" links with custom shapes" );
	}

	/**
		Compress link shapes; removes all shapes that are redundant with the cannonical shapes from their links
	**/
	public function compressShapes() {
		var oldShapes = sim.state.shapes; // just a shortcut
		if ( oldShapes == null )
			return;
		println( "Compressing link shape data" );
		var shapes = new Map();
		for ( s in oldShapes )
			if ( s.shape.length > 2 )
				shapes.set( s.linkId, s );
		sim.state.shapes = shapes;
		println( "All shapes with only 2 points have been removed" );
	}

	/**
		Clear link shapes; when necessary the default ones (that are based on
		start and finish nodes)
	**/
	public function clearShapes() {
		if ( sim.state.shapes != null ) {
			println( "Clearing link shape data; default shapes will be used" );
			sim.state.shapes = null;
		}
	}

	/**
		Write link shapes to LinkShape ETT in `path`, using optional `filter`;
		will overwrite existing files
	**/
	public function ettShapes( path:String, ?filter:String ) {
		var shapes:Iterable<LinkShape> = sim.state.shapes;
		if ( filter != null ) {
			var q = Search.prepare( filter, "linkId" );
			shapes = q.execute( sim, sim.state.shapes, sim.state.aliases );
		}
		return _genericEtt( path, shapes, LinkShape, "Writing link shapes", "No link shapes" );
	}

	/**
		Fix invalid shapes
	**/
	public function fixShapes( precision:Float ) {
		if ( sim.state.shapes == null ) {
			println( "No shapes" );
			return;
		}

		var feq = function ( a:Float, b:Float ) return Math.abs( a - b ) < precision;

		println( "Checking and fixing link shapes" );

		var errcnt = 0;
		var warcnt = 0;

		sim.state.identation++;

		var nshapes = new Map();
		for ( shp in sim.state.shapes ) {
			var pts = shp.shape.array();

			// internal constraints
			var npts = [];
			var pre:format.ett.Geometry.Point = null; // `pre` in the last point **kept**
			for ( pi in 0...pts.length ) {
				var pt = pts[pi];
				if ( pi > 0 ) {
					if ( feq( pt.x, pre.x ) && feq( pt.y, pre.y ) ) {
						if ( npts.length == 1 ) {
							println( "WARNING at link `"+shp.linkId+"`: link shape smaller than precision" );
							warcnt++;
						}
						else {
							println( "Fixed error at link `"+shp.linkId+"`: skipping duplicate point "+(pi+1) );
							errcnt++;
							if ( pi == pts.length - 1 )
								npts[npts.length-1] = pt;
						}
					}
					else {
						npts.push( pre = pt );
					}
				}
				else {
					npts.push( pre = pt );
				}
			}
			pts = null; // pts should no longer be used beyond here

			// external constraints
			var link = sim.state.links.get( shp.linkId );
			var snpt = sim.state.nodes.get( link.startNodeId ).point;
			var tnpt = sim.state.nodes.get( link.finishNodeId ).point;
			if ( npts.length < 2 ) {
				println( "Fixed error at link `"+shp.linkId+"`: invalid number of points in shape" );
				errcnt++;
				continue;
			}
			else if ( !feq( npts[0].x, snpt.x ) || !feq( npts[0].y, snpt.y ) ) {
				println( "WARNING at link `"+shp.linkId+"`: first point doesn't match its corresponding node coordinates" );
				warcnt++;
			}
			else if ( !feq( npts[npts.length-1].x, tnpt.x ) || !feq( npts[npts.length-1].y, tnpt.y ) ) {
				println( "WARNING at link `"+shp.linkId+"`: last point doesn't match its corresponding node coordinates" );
				warcnt++;
			}
			else {
				nshapes.set( shp.linkId, LinkShape.make( shp.linkId, new format.ett.Geometry.LineString( npts ) ) );
			}

		}

		sim.state.identation--;

		sim.state.shapes = nshapes;
		println( "Fixed "+errcnt+" errors and issued another "+warcnt+" warnings" );
	}



	// LINK ALIASES -------------------------------------------------------------

	/**
		Read link aliases from LinkAlias ETT in `path` (reentrant); aliases for
		unknown links are just ignored
	**/
	public function readAliases( path:String ) {
		if ( sim.state.aliases == null ) {
			println( "Reading link aliases" );
			sim.state.aliases = new Map();
		}
		else {
			println( "Reading additional link aliases; overwriting when necessary" );
		}
		var links = sim.state.links; // just a shortcut
		if ( links == null || !links.iterator().hasNext() )
			return; // no links
		var aliases = sim.state.aliases; // just a shortcut
		var einp = _readEtt( path );
		while ( true ) {
			var alias = try { einp.fastReadRecord( LinkAlias.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( alias == null ) break;
			if ( links.exists( alias.linkId ) )
				if ( aliases.exists( alias.name ) )
					aliases.get( alias.name ).push( alias.linkId );
				else
					aliases.set( alias.name, [ alias.linkId ] );
		}
		einp.close();
	}

	/**
		Clear all aliases
	**/
	public function clearAliases() {
		sim.state.aliases = null;
	}

	/**
		Show aliases
	**/
	public function showAliases() {
		if ( sim.state.aliases == null )
			println( "No aliases" );
		var aliases = sim.state.aliases;
		var names = [ for ( name in aliases.keys() ) name ];
		names.sort( Reflect.compare );
		println( "Showing aliases:" );
		for ( name in names ) {
			var cnt = count( aliases.get( name ) );
			println( "  \""+name+"\": "+cnt+" links" );
		}
	}

	/**
		Write link aliases to LinkAlias ETT in `path`
	**/
	public function ettAliases( path:String ) {
		var aliases = null;
		if ( sim.state.aliases != null ) {
			aliases = [];
			var as = sim.state.aliases;
			for ( alias in as.keys() )
				for ( linkId in as.get( alias ) )
					aliases.push( LinkAlias.make( alias, linkId ) );
		}
		return _genericEtt( path, aliases, LinkAlias, "Writing link aliases", "No link aliases" );
	}



	// VEHICLE I/O --------------------------------------------------------------

	/**
		Read vehicles from Vehicle ETT in `path` (reentrant)
	**/
	public function readVehicles( path:String ) {
		if ( sim.state.vehicles == null ) {
			println( "Reading vehicles" );
			sim.state.vehicles = new Map();
		}
		else {
			println( "Reading additional vehicles" );
		}
		var vehicles = sim.state.vehicles; // just a shortcut
		var einp = _readEtt( path );
		sim.state.invalidate(); // this might (and should) not be necessary in the future
		while ( true ) {
			var type = try { einp.fastReadRecord( Vehicle.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( type == null ) break;
			vehicles.set( type.id, type );
		}
		einp.close();
	}

	/**
		Show vehicles
	**/
	public function showVehicles() {
		println( "Known types:" );
		println( _right("id",6)+"  |  name" );
		printHL( "-" );
		for ( type in sim.state.vehicles )
			println( _right(type.id,6)+"  |  "+type.name );
	}

	/**
		Count vehicles
	**/
	public function countVehicles() {
		var cnt = sim.state.vehicles != null ? count( sim.state.vehicles ) : 0;
		println( "Counted "+cnt+" vehicles" );
	}



	// LINK TYPE SPEED I/O ------------------------------------------------------

	/**
		Read speeds for (link type,vehicle) pairs from LinkTypeSpeed ETT in `path`
		(reentrant); requires link types and vehicles; speeds should be in km/h
	**/
	public function readSpeeds( path:String ) {
		if ( sim.state.speeds == null ) {
			println( "Reading link type speeds" );
			sim.state.speeds = new LinkTypeSpeedMap();
		}
		else {
			println( "Reading additional link type speeds" );
		}
		var linkTypes = sim.state.linkTypes; // just a shortcut
		var vehicles = sim.state.vehicles; // just a shortcut
		if ( linkTypes == null ) throw "No link types";
		if ( vehicles == null ) throw "No vehicles";
		var speeds = sim.state.speeds; // just a shortcut
		var einp = _readEtt( path );
		sim.state.invalidate(); // this might (and should) not be necessary in the future
		while ( true ) {
			var speed = try { einp.fastReadRecord( LinkTypeSpeed.makeEmpty() ); }
			            catch ( e:Eof ) { null; };
			if ( speed == null ) break;
			if ( !linkTypes.exists( speed.typeId ) )
				throw "Missing link type "+speed.typeId;
			if ( !vehicles.exists( speed.vehicleId ) )
				throw "Missing vehicle "+speed.vehicleId;
			speeds.set( speed, speed );
		}
		einp.close();
	}

	/**
		Show speeds for type id `type-id` and vehicle id `vehicle-id`;
		id set to "_" will be treated as non restrictive filters
	**/
	public function showSpeeds( tid:String, vid:String ) {
		var t:Null<Int> = _readInt( tid );
		var v:Null<Int> = _readInt( vid );
		print( "Link speeds for " );
		print( t != null ? " typeId="+t+" " : "all link types " );
		println( v != null ? " vehicleId="+v+" " : "all vehicles:" );
		println( _right("type",6)+"  |  "+_right("vehicle",8)+"  |  speed (km/h" );
		printHL( "-" );
		// TODO get typeId,vehicleId from the other collections and show missing values
		if ( sim.state.speeds == null )
			throw "No speeds";
		var speeds = [ for ( s in sim.state.speeds ) s ];
		speeds.sort( function (a,b) return 2*Reflect.compare(a.typeId,b.typeId)+Reflect.compare(a.vehicleId,b.vehicleId) );
		for ( speed in speeds )
			if ( ( t == null || speed.typeId == t )
			&& ( v == null || speed.vehicleId == v ) )
				println( _right(speed.typeId,6)+"  |  "+_right(speed.vehicleId,8)+"  |  "+speed.speed );
	}



	// ONLINE NETWORK UPDATES ---------------------------------------------------

	/**
		Update link properties (`extension`, `typedId` or `toll`); this forces
		a full online network and digraph reassembly before the next run
	**/
	public function updateLinks( filter:String, update:String ) {
		println( "Updating links matching '"+filter+"' with '"+update+"'" );
		var links = sim.state.links;
		if ( links == null )
			throw "No links";
		var aliases = sim.state.aliases;
		var q = Search.prepare( filter, "id" );
		var set = array( q.execute( sim, links, aliases ) );
		var u = Update.prepare( update, ["extension", "typeId", "toll"] );
		sim.state.invalidate();
		u.execute( set );
	}



	// O/D I/O ------------------------------------------------------------------

	/**
		Read O/D data from OD ETT in `path` (reentrant); requires vehicles; costs
		should be in $/km (distance multipliers) and and $/h (time multipliers);
		when applicable, custom sample weights may be reset
	**/
	public function readOd( path:String ) {
		if ( sim.state.ods == null ) {
			println( "Reading O/D data" );
			sim.state.ods = new Map();
		}
		else {
			println( "Reading additional O/D data" );
			sim.state.activeOds = null;
			sim.state.activeOdFilter = null;
		}
		var vehicles = sim.state.vehicles; // just a shortcut
		var ods = sim.state.ods; // just a shortcut
		var wgts = sim.state.sampleWeights;
		if ( vehicles == null ) throw "No vehicles";
		var einp = _readEtt( path );
		while ( true ) {
			var od = try { einp.fastReadRecord( OD.makeEmpty() ); }
			         catch ( e:Eof ) { null; };
			if ( od == null ) break;
			if ( !vehicles.exists( od.vehicleId ) )
			if ( !vehicles.exists( od.vehicleId ) )
				throw "Missing vehicle "+od.vehicleId;
			ods.set( od.id, od );
			if ( wgts != null )
				wgts.remove( od.id );
		}
		einp.close();
	}

	/**
		Show (filtered) O/D records with optional `filter` expression and output
		`type`; `type` can be "show", "head" or "count" (default)
	**/
	public function queryOds( ?filter="true==true", ?type="count" ) {
		var q = Search.prepare( filter, "id" );
		var idx = sim.state.activeOds != null ? sim.state.activeOds : sim.state.ods;
		_genericQuery( q, idx, null, type
		, "Searching OD records matching '"+filter+"'", "No OD records" );
	}

	/**
		Show all (ignore any filter) O/D records with optional `filter`
		expression and output `type`; `type` can be "show", "head" or
		"count" (default)
	**/
	public function queryAllOds( ?filter="true==true", ?type="count" ) {
		var q = Search.prepare( filter, "id" );
		_genericQuery( q, sim.state.ods, null, type
		, "Searching OD records matching '"+filter+"'", "No OD records" );
	}

	/**
		Clear O/D records; this removes any results or volumes
		(active or cold stored)
	**/
	public function clearOd() {
		clearStorage();
		clearResults();
		clearOdFilter();
		sim.state.ods = null;
	}

	/**
		Write (filtered) O/D records to OD ETT in `path`, using optional `filter`;
		will overwrite existing files
	**/
	public function ettOds( path:String, ?filter:String ) {
		var idx = sim.state.activeOds != null ? sim.state.activeOds : sim.state.ods;
		var ods:Iterable<OD> = idx;
		if ( filter != null ) {
			var q = Search.prepare( filter, "id" );
			ods = q.execute( sim, idx, null );
		}
		return _genericEtt( path, ods, OD, "Writing O/D records", "No O/D records" );
	}

	/**
		Write all (ignore any filter) O/D records to OD ETT in `path`, using
		optional `filter`; will overwrite existing files
	**/
	public function ettAllOds( path:String, ?filter:String ) {
		var ods:Iterable<OD> = sim.state.ods;
		if ( filter != null ) {
			var q = Search.prepare( filter, "id" );
			ods = q.execute( sim, sim.state.ods, null );
		}
		return _genericEtt( path, ods, OD, "Writing O/D records", "No O/D records" );
	}



	// O/D FILTERS --------------------------------------------------------------

	/**
		Filter remaining O/D data (reentrant); supported filter `type`s are "id",
		"lot", "section", "direction", "vehicle" (vehicle id) and "cargo"; `clause`
		may be "_" (no filter), a value or a comma separated list of values
	**/
	public function filterOd( type:String, clause:String ) {
		var ods = sim.state.ods;
		if ( ods == null ) throw "No O/D data";
		var activeOds = sim.state.activeOds != null ? sim.state.activeOds : _odMap( sim.state.ods );
		var activeOdFilter = sim.state.activeOdFilter; if ( activeOdFilter == null ) activeOdFilter = [];
		sim.state.activeOds = _odMap( _innerOdQuery( activeOds, type, clause, activeOdFilter ) );
		sim.state.activeOdFilter = activeOdFilter;
		println( "Current selected records: "+count( activeOds ) );
		showOdFilter();
	}

	/**
		Show O/D filter expression
	**/
	public function showOdFilter() {
		if ( sim.state.activeOdFilter == null )
			println( "No O/D filter at the moment... All available data selected" );
		else
			println( "Selected O/D records with "+sim.state.activeOdFilter.join( " && " ) );
	}

	/**
		Clear O/D filter; reselects all O/D records
	**/
	public function clearOdFilter() {
		sim.state.activeOds = null;
		sim.state.activeOdFilter = null;
	}



	// EXPANSION FACTORS --------------------------------------------------------

	/**
		Alter sample weights according to criteria `type` and `clause` by
		setting them to `value`; any remaining volumes are lost
	**/
	public function setWeight( type:String, clause:String, value:Float ) {
		sim.state.volumes = null;
		if ( sim.state.ods == null )
			throw "No O/D data";
		var exp = sim.state.sampleWeights;
		if ( exp == null )
			exp = sim.state.sampleWeights = new Map();
		var q = _innerOdQuery( sim.state.ods, type, clause );
		sim.state.volumes = null;
		for ( od in q )
			exp.set( od.id, value );
	}

	/**
		Alter sample weights according to criteria `type` and `clause` by
		multiplying current values by `multi`; any remaining volumes are lost
	**/
	public function alterWeight( type:String, clause:String, multi:Float ) {
		sim.state.volumes = null;
		if ( sim.state.ods == null )
			throw "No O/D data";
		var exp = sim.state.sampleWeights;
		if ( exp == null )
			exp = sim.state.sampleWeights = new Map();
		var q = _innerOdQuery( sim.state.ods, type, clause );
		for ( od in q ) {
			var previous = exp.exists( od.id ) ? exp.get( od.id ) : od.sampleWeight;
			exp.set( od.id, od.sampleWeight*multi );
		}
	}

	/**
		Resets all sample weights to their value on the O/D record; any remaining
		volumes are lost
	**/
	public function resetWeights( type:String, clause:String, multi:Float ) {
		sim.state.volumes = null;
		sim.state.sampleWeights = null;
	}



	// RUNNING ------------------------------------------------------------------

	/**
		Set the algorithm base to `name`; supported algorithms at the moment are
		"Dijstra" and "A*"
	**/
	public function setAlgorithm( name:String ) {
		var algo = switch ( name.toLowerCase() ) {
		case "dijkstra", "ijk", "dijk", "dijstras":
			ADijkstra;
		case "a*", "astar", "a-star", "star":
			AAStar;
		case "bellman-ford", "bford", "bell", "ford":
			ABellmanFord;
			throw "Bellman-Ford algorithm has been disabled";
		case all:
			throw "Unknown algorithm "+all;
		};
		if ( algo != sim.state.algorithm ) {
			var old = algoName( sim.state.algorithm );
			var newName = algoName( algo );
			sim.state.algorithm = algo;
			sim.state.invalidate();
			println( "Algorithm changed from "+old+" to "+newName );
		}
	}

	/**
		Show the current selected base algorithm
	**/
	public function showAlgorithm() {
		println( "Current algorithm: "+algoName(sim.state.algorithm) );
	}
	private function algoName( a:Algorithm ) {
		return switch ( a ) {
		case ADijkstra: "Dijkstra";
		case AAStar: "A*";
		case ABellmanFord: "Bellman-Ford";
		};
	}

	/**
		Execute/run saving `volumes` and/or `path`
	**/
	public function run( ?volumes:String, ?path:String ) {
		var ods:Iterable<OD> = sim.state.activeOds != null ? sim.state.activeOds : sim.state.ods;
		if ( ods == null ) throw "No O/D data";
		if ( !ods.iterator().hasNext() ) {
			println( "No O/D records... Try to remove the filter with --clear-od-filter" );
			return;
		}
		var saveVols = _readBool( volumes, true );
		var savePath = _readBool( path, true );
		sim.state.assemble();
		if ( sim.state.results == null ) sim.state.results = new Map();
		if ( saveVols && sim.state.volumes == null ) sim.state.volumes = new Map();
		if ( saveVols ) println( "Saving link volumes" );
		if ( savePath ) println( "Saving selected paths" );
		showAlgorithm();
		sim.state.digraph.run( ods, saveVols, savePath, sim.state, true );
	}

	/**
		Clear all previous results
	**/
	public function clearResults() {
		sim.state.clearResults();
	}



	// RESULT STORAGE AND STORAGE I/O -------------------------------------------

	/**
		Save results in cold storage for later output or visualization under `key`;
		defaults to saving link volumes and paths; this effectively removes these
		results from the active simulator state, so they are _no_ longer available
		to regular analysis and export tools
	**/
	public function storeResults( key:String, ?saveVolumes:String, ?savePaths:String ) {
		if ( sim.state.results == null )
			throw "No results";

		var vols = _readBool( saveVolumes );
		if ( vols == null ) vols = true;
		var paths = _readBool( savePaths );
		if ( paths == null ) paths = true;

		if ( vols && sim.state.volumes == null )
			throw "No volumes";

		if ( sim.state.coldStorage == null )
			sim.state.coldStorage = new Map();
		else if ( sim.state.coldStorage.exists( key ) )
			println( "This results will overwrite the previous ones for key \""+key+"\"" );

		var rs = sim.state.results;
		var vs = vols ? sim.state.volumes : null;
		var st = sim.state.coldStorage;

		var box = new StorageBox( key, rs, vs, !paths );

		st.set( box.key, box );

		sim.state.results = null;
		sim.state.volumes = null;
	}

	/**
		Restore cold stored results; this removes then from cold storage and puts
		them in the active simulator state, so they are available for regular
		analysis and export tools such as --analyze, --ett-results and
		--geojson-volumes
	**/
	public function restoreResults( key:String ) {
		if ( sim.state.coldStorage == null )
			throw "No cold storage";

		var box = sim.state.coldStorage.get( key );
		if ( box == null )
			throw "No box for \""+key+"\"";

		var res = new Map();
		for ( r in box.results() )
			res.set( r.odId, r );
		if ( sim.state.results != null )
			println( "Replacing active results" );
		sim.state.results = res;

		var bvols = box.volumes();
		if ( bvols != null ) {
			var vols = new Map();
			for ( v in bvols )
				vols.set( v.linkId, v );
			if ( sim.state.volumes != null )
				println( "Replacing active results" );
			sim.state.volumes = vols;
		}

		sim.state.coldStorage.remove( key );
	}

	/**
		Show cold storage simplified manifest: key and number of results/volumes
		stored for it
	**/
	public function showStorage() {
		if ( sim.state.coldStorage == null )
			throw "No cold storage";

		var st = sim.state.coldStorage;
		var keys = [ for ( k in st.keys() ) k ];
		if ( keys.length == 0 ) {
			println( "Cold storage is empty" );
			return;
		}

		println( "Cold storage contents:" );
		keys.sort( Reflect.compare );
		for ( k in keys ) {
			var box = st.get( k );
			println( tabs(1)+"Box labeled \""+k+"\": "+box.countResults()
			+" results and "+box.countVolumes()+" volumes" );
		}
	}

	/**
		Write aggregated ETT for all results in cold storage; output to ODResult
		ETT in `path`
	**/
	public function ettStorage( path:String ) {
		println( "Writing cold stored results in ETT" );
		if ( sim.state.coldStorage == null )
			throw "No cold storage";
		var eout = _writeEtt( ODResult, ODResult.ettFields(), path );
		for ( box in sim.state.coldStorage )
			for ( r in box.results() )
				eout.write( r );
		eout.close();
	}

	/**
		Write aggregated GeoJSON for all volumes in cold storage; output to
		GeoJSON file in `path`
	**/
	public function geojsonStorage( path:String ) {
		println( "Mapping cold stored volumes in GeoJSON" );
		var st = sim.state.coldStorage; // just a shortcut
		if ( st == null ) throw "No cold storage";
		var fout = _writeFile( path, false );
		fout.writeString( '{"type":"FeatureCollection","features":['+sim.state.newline );
		var first = true;
		for ( box in st )
			for ( v in box.volumes() ) {
				if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
				fout.writeString( _geojsonVolume( v, '"key":"${box.key}"' ) );
			}
		fout.writeString( sim.state.newline+"] }"+sim.state.newline );
		fout.close();
	}

	/**
		Write aggregated Shapefile set (preffixed by `path`) for all volumes in cold storage
	**/
	public function shpStorage( path:String ) {
		println( "Mapping cold stored volumes in ESRI Shapefile" );
		_shp( function (p,f) geojsonStorage(p), path, null );
	}

	/**
		Discart all results in cold storage
	**/
	public function clearStorage() {
		if ( sim.state.coldStorage != null )
			sim.state.coldStorage = null;
	}



	// VOLUME I/O ---------------------------------------------------------------

	/**
		Search link volumes with optional `filter` expression and output `type`;
		`type` can be "show", "head" or "count" (default)
	**/
	public function queryVolumes( ?filter="true==true", ?type="count" ) {
		var q = Search.prepare( filter, "linkId" );
		_genericQuery( q, sim.state.volumes, sim.state.aliases, type
		, "Searching link volumes matching '"+filter+"'", "No volumes" );
	}

	/**
		Write volumes to LinkVolume ETT in `path`; will overwrite existing files
	**/
	public function ettVolumes( path:String ) {
		_genericEtt( path, sim.state.volumes, LinkVolume, "Writing volumes", "No volumes" );
	}

	/**
		Write volumes to GeoJSON in `path` using available link shape data; will
		overwrite existing files
	**/
	public function geojsonVolumes( path:String ) {
		println( "Mapping volumes in GeoJSON" );
		var volumes = sim.state.volumes; // just a shortcut
		if ( volumes == null ) throw "No volumes";
		var fout = _writeFile( path, false );
		fout.writeString( '{"type":"FeatureCollection","features":['+sim.state.newline );
		var first = true;
		for ( v in volumes ) {
			if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
			fout.writeString( _geojsonVolume( v, null ) );
		}
		fout.writeString( sim.state.newline+"] }"+sim.state.newline );
		fout.close();
	}

	/**
		Write volumes to Shapefile set preffixed by `path` using available link shape data; will
		overwrite existing files
	**/
	public function shpVolumes( path:String ) {
		println( "Mapping volumes in ESRI Shapefile" );
		_shp( function (p,f) geojsonVolumes(p), path, null );
	}

	/**
		Store a copy of the current volumes for later use as reference
	**/
	public function saveVolumeReference() {
		var volumes = sim.state.volumes;
		if ( volumes == null )
			throw "No volumes";
		var refVolumes = new Map();
		for ( v in volumes )
			refVolumes.set( v.linkId, v.copy() );
		sim.state.refVolumes = refVolumes;
	}

	/**
		Generate a comparission between current and reference volumes and write
		it to GeoJSON in `path`, using available link shape data; will overwrite
		existing files
	**/
	public function geojsonVolumeDiff( path:String ) {
		println( "Mapping volumes in GeoJSON" );
		var volumes = sim.state.volumes; // just a shortcut
		var refVolumes = sim.state.refVolumes; // just a shortcut
		if ( volumes == null ) throw "No volumes";
		if ( refVolumes == null ) throw "No reference volumes";
		var fout = _writeFile( path, false );
		fout.writeString( '{"type":"FeatureCollection","features":['+sim.state.newline );
		var first = true;
		for ( v in volumes ) {
			if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
			var ref = refVolumes.get( v.linkId );
			if ( ref != null ) {
				var v_ = v.copy();
				v_.sub( ref );
				fout.writeString( _geojsonVolume( v_, null ) );
			}
			else {
				fout.writeString( _geojsonVolume( v, null ) );
			}
		}
		for ( ref in refVolumes ) {
			if ( !volumes.exists( ref.linkId ) ) {
				if ( first ) first = false; else fout.writeString( ","+sim.state.newline+"\t" );
				var v_ = LinkVolume.make( ref.linkId, 0, 0, 0, 0 );
				v_.sub( ref );
				fout.writeString( _geojsonVolume( v_, null ) );
			}
		}
		fout.writeString( sim.state.newline+"] }"+sim.state.newline );
		fout.close();
	}

	/**
		Generate a comparission between current and reference volumes and write
		it to Shapefile set preffixed by `path`, using available link shape data; will overwrite
		existing files
	**/
	public function shpVolumeDiff( path:String ) {
		println( "Mapping volumes in ESRI Shapefile" );
		_shp( function (p,f) geojsonVolumeDiff(p), path, null );
	}

	

	// RESULTS I/O --------------------------------------------------------------

	/**
		Show results with optional `filter` expression and output `type`;
		`type` can be "show", "head" or "count" (default)
	**/
	public function queryResults( ?filter="true==true", ?type="count" ) {
		var q = Search.prepare( filter, "odId" );
		_genericQuery( q, sim.state.volumes, sim.state.aliases, type
		, "Searching results matching '"+filter+"'", "No results" );
	}


	/**
		Write results to ODResults ETT in `path`; will overwrite existing files
	**/
	public function ettResults( path:String ) {
		_genericEtt( path, sim.state.results, ODResult, "Writing results", "No results" );
	}



	// RESULT ANALYSIS ----------------------------------------------------------

	/**
		Analyze links matching `query`, optionally `type` may be used to limit
		the analysis; it can be a comma separated list of "volumes", "ods",
		"usage", "save-usage" or "_" (for everything, the default); requires
		results with saved paths and volumes (when applicable); other values for
		`type` are "filter-ods" and "filter-outside-ods", that set the od filter
		acordingly
	**/
	public function analyze( query:String, ?type:String ) {
		if ( sim.state.links == null )
			throw "No links";

		var q = Search.prepare( query, "id" );
		var links = array( q.execute( sim, sim.state.links, sim.state.aliases ) );
		if ( links.length == 0 )
			throw "No links matching query '"+query+"'";
		var linkIds = links.map( function (x) return x.id );

		var ods = sim.state.ods;
		var vehicles = sim.state.vehicles;

		var azVol = false;
		var azOds = false;
		var azUsg = false;
		var svUsg = false;
		var frOds = false;
		var frOsOds = false;

		var types = _readSet( type, true );
		if ( types == null )
			azVol = azOds = azUsg = svUsg = true;
		else for ( t in types ) {
			switch ( t.toLowerCase() ) {
			case "volumes", "volume", "vol":
				azVol = true;
			case "ods", "pairs", "od":
				azOds = true;
			case "usage":
				azUsg = true;
			case "save-usage", "save", "toll":
				svUsg = true;
			case "users":
				throw "No analysis type \"users\"; did you mean \"usage\" or \"ods\"";
			case "filter-ods":
				frOds = true;
			case "filter-outside-ods":
				frOsOds = true;
			case all:
				throw "No analysis type \""+all+"\"";
			}
		}

		if ( frOds && frOsOds ) throw "Cannot simultaneouly filter o/d records both passing and not passing";
		azUsg = azUsg || svUsg;

		var res = sim.state.results;
		if ( res == null )
			throw "No results";

		println( "Analyzing links ["+linkIds.join(", ")+"]" );

		var resCnt = 0;
		var users = null; // array of OD::id
		var totalWeight = 0.;
		var userWeight = 0.;

		if ( azUsg || azOds || frOds || frOsOds ) { // output O/D record ids
			users = [];
			for ( r in res ) {
				if ( r.path != null ) {
					if ( svUsg && r.escaped == null )
						r.escaped = true;
					var isUser = false;
					for ( link in links ) {
						if ( has( r.path, link.id ) ) {
							isUser = true;
							break;
						}
					}
					resCnt++;
					var tolls = r.weight*vehicles.get(ods.get(r.odId).vehicleId).tollMulti;
					totalWeight += tolls;
					if ( isUser ) {
						users.push( r.odId );
						userWeight += tolls;
						if ( svUsg ) r.escaped = false;
					}
				}
				else if ( svUsg )
					r.escaped = null;
			}
			users.sort( Reflect.compare );

			if ( frOds ) {
				sim.state.activeOdFilter = [ "Passing through '"+query+"'" ];
				sim.state.activeOds = _odMap( users.map( ods.get ) );
				showOdFilter();
			}

			if ( frOsOds ) {
				sim.state.activeOdFilter = [ "NOT passing through '"+query+"'" ];
				var tset = new Map();
				for ( odId in users )
					tset.set( odId, odId );
				var f = [];
				for ( r in res )
					if ( !tset.exists( r.odId ) )
						f.push( ods.get( r.odId ) );
				sim.state.activeOds = _odMap( f );
				showOdFilter();
			}

			if ( azOds )
				println( tabs(1)+users.length+" O/D records using links ["
				+linkIds.join(", ")+"]: "+users.join(", ") );
			if ( resCnt == 0 )
				println( tabs(1)+"WARNING: no OD results with path information;"
				+" maybe this was lost during lossy cold storage (--store-results) or this was never saved in --run" );
		}

		if ( azVol ) { // output volumes
			var vols = sim.state.volumes;
			if ( vols == null )
				throw "No volumes";
			for ( link in links ) {
				var v = vols.exists( link.id ) ? vols.get( link.id ) : LinkVolume.make( 0, 0, 0, 0, 0 );
				println( tabs(1)+"link volumes for link '"+link.id+"':");
				println( tabs(2)+_left(_strnum(v.vehicles,2,0),9)+"  vehicles" );
				println( tabs(2)+_left(_strnum(v.equivalentVehicles,2,0),9)+"  equivalent vehicles" );
				println( tabs(2)+_left(_strnum(v.axis,2,0),9)+"  axis" );
				println( tabs(2)+_left(_strnum(v.tolls,2,0),9)+"  toll multipliers" );
			}
		}

		if ( azUsg && resCnt > 0 ) { // output usage (prob) and error
			println( tabs(1)+"result analysis:" );
			var n = resCnt;
			println( tabs(1)+_left(n,5)+"  allocated O/D pairs" );
			var p = users.length/resCnt;
			println( tabs(1)+_left(users.length,5)+"  pairs using ("+_strnum(p*100,1,1)+"%)" );
			if ( p > 0 ) {
				var s = Math.sqrt( n*p*( 1. - p ) );
				println( tabs(1)+_left(_strnum(s,2,0),5)+"  standard deviation ("+_strnum(s/n*100,1,1)+"%)" );
				println( tabs(1)+"error(+/-):        NPQ    Wald   Agresti-Coull" );
				printError( resCnt, p, .7 );
				printError( resCnt, p, .9 );
				printError( resCnt, p, .95 );
			}
			println( tabs(1)+_left(_strnum(totalWeight,1,0),5)+"  potential toll fares" );
			var P = userWeight/totalWeight;
			println( tabs(1)+_left(_strnum(userWeight,1,0),5)+"  actual toll fares ("+_strnum(P*100,1,1)+"%)" );
			if ( P > 0 ) {
				var S = Math.sqrt( totalWeight*P*(1.-P) );
				println( tabs(1)+_left(_strnum(S,2,0),5)+"  standard deviation ("+_strnum(S/totalWeight*100,1,1)+"%)" );
				println( tabs(1)+"error(+/-):        NPQ    Wald   Agresti-Coull" );
				printError( totalWeight, P, .7 );
				printError( totalWeight, P, .9 );
				printError( totalWeight, P, .95 );
			}
		}

	}
	private function pConf_NPQ( sampleSize:Float, prob:Float, a:Float ) {
		return zscore( .5*a )*Math.sqrt( sampleSize*prob*( 1. - prob ) )/sampleSize;
	}
	private function pConf_Wald( sampleSize:Float, prob:Float, a:Float ) {
		return zscore( .5*a )*Math.sqrt( prob*( 1. - prob )/sampleSize );
	}
	private function pConf_AgrestiCoull( sampleSize:Float, prob:Float, a:Float ) {
		var _prob = ( sampleSize*prob + .5*zscore( .5*a ) )
		           /(   sampleSize   + zscore( .5*a )*zscore( .5*a ) );
		return zscore( a*.5 )*Math.sqrt( _prob*( 1. - _prob )/sampleSize );
	}
	private function zscore( a:Float ) {
		return stat.ZScore.forProbGreaterThan( 1.-a );
	}
	private function printError( sampleSize:Float, prob:Float, conf:Float ) {
		println( "        conf. "+_strnum(conf*100,0,1)+"%: "+_strnum(pConf_NPQ(sampleSize,prob,(1-conf))*100,2,6)
		+"% "+_strnum(pConf_Wald(sampleSize,prob,(1-conf))*100,2,6)
		+"% "+_strnum(pConf_AgrestiCoull(sampleSize,prob,(1-conf))*100,2,14)+"%" );
	}



	// NETWORK MANIPULATION -----------------------------------------------------

	/**
		Add a new node with coordinates (`x` and `y`) and `id`
	**/
	public function addNode( x:String, y:String, id:Int ) {
		if ( sim.state.nodes == null )
			sim.state.nodes = new Map();
		if ( sim.state.nodes.exists( id ) )
			throw "Node `"+id+"` already exists";

		sim.state.invalidate();
		var node = Node.make( id, new format.ett.Geometry.Point( _readFloat(x), _readFloat(y) ) );
		sim.state.nodes.set( node.id, node );
	}

	/**
		Add a new link from node `startId` to node `finishId`, with `extension`, `typeId`, `toll` and `id`
	**/
	public function addLink( startId:Int, finishId:Int, extension:Float, typeId:Int, toll:Float, id:Int ) {
		if ( sim.state.nodes == null )
			throw "No nodes";
		if ( !sim.state.nodes.exists( startId ) )
			throw "Origin node `"+startId+"` does not exist";
		if ( !sim.state.nodes.exists( finishId ) )
			throw "Destination node `"+finishId+"` does not exist";
		if ( sim.state.linkTypes == null )
			throw "No link types";
		if ( !sim.state.linkTypes.exists( typeId ) )
			throw "Link type `"+typeId+"` does not exists";
		if ( sim.state.links == null )
			sim.state.links = new Map();
		if ( sim.state.links.exists( id ) )
			throw "Link `"+id+"` already exists";

		sim.state.invalidate();
		var link = Link.make( id, startId, finishId, extension, typeId, toll );
		sim.state.links.set( link.id, link );
	}

	/**
		Create the reverse link for `src`, with id `dst`; if `cloneAliases` is true, all aliases pointing to `src` will
		also point to `dst`
	**/
	public function reverseLink( src:Int, dst:Int, ?cloneAliases:String ) {
		if ( sim.state.links == null )
			sim.state.links = new Map();
		if ( !sim.state.links.exists( src ) )
			throw "Link `"+src+"` does not exist";
		if ( sim.state.links.exists( dst ) )
			throw "Link `"+dst+"` already exists";

		sim.state.invalidate();
		var link = sim.state.links.get( src );
		var shape = _getShape( link ).shape.array();

		var rev = Link.make( dst, link.finishNodeId, link.startNodeId, link.extension, link.typeId, link.toll );
		sim.state.links.set( rev.id, rev );
		var revShape = shape.copy();
		revShape.reverse();
		var rshp = LinkShape.make( rev.id, new format.ett.Geometry.LineString( revShape ) );
		sim.state.shapes.set( rshp.linkId, rshp );
		
		if ( sim.state.aliases != null && _readBool( cloneAliases ) )
			state.cloneLinkAliases( link, rev );
	}

	/**
		Split link `linkId` on node `nodeId`, creating two new links (`dst1` and `dst2`); if `cloneAliases` is true, all
		aliases pointing to `src` will also point to `dst`
	**/
	public function splitLink( linkId:Int, nodeId:Int, dst1:Int, dst2:Int, ?cloneAliases:String ) {
		sim.state.invalidate();
		var ret = Splitter.split( state, linkId, nodeId, dst1, dst2, _readBool( cloneAliases ) == true );
		// trace( ret.link1 );
		// trace( ret.link2 );
	}

	/**
		Make alias `alias` point also to all links matching `query`
	**/
	public function setAlias( alias:String, query:String ) {
		// var links = _readSet( query, false ).map( function (s) return state.getLink( parseInt(s) ) );
		var links = Search.prepare( query, "id" ).execute( sim, state.links, state.aliases );
		state.setAlias( alias, links );
	}

	/**
		Remove links matching `query` from destinations for alias `alias`
	**/
	public function unsetAlias( alias:String, ?query:String ) {
		// var lids = _readSet( query );
		if ( query == null ) {
			state.unsetAlias( alias );
		}
		else {
			// var links = lids.map( function (s) return state.getLink( parseInt(s) ) );
			var links = Search.prepare( query, "id" ).execute( sim, state.links, state.aliases );
			state.setAlias( alias, links );
		}
	}

	/**
		Compress the current network, eliminating nodes and links that are no longer necessary
	**/
	public function compressNetwork() {
		// trace( count( sim.state.nodes ) );
		// trace( count( sim.state.links ) );
		// trace( sim.state.shapes != null ? count( sim.state.shapes ) : 0 );
		// trace( sim.state.aliases != null ? count( sim.state.aliases ) : 0 );

		var compressor = NetworkCompressor.compress( sim.state );
		
		sim.state.invalidate();
		sim.state.nodes = compressor.nodes;
		sim.state.links = compressor.links;
		sim.state.shapes = compressor.shapes;
		sim.state.aliases = compressor.aliases;

		// trace( count( sim.state.nodes ) );
		// trace( count( sim.state.links ) );
		// trace( sim.state.shapes != null ? count( sim.state.shapes ) : 0 );
		// trace( sim.state.aliases != null ? count( sim.state.aliases ) : 0 );
	}



	// COMMAND HISTORY ----------------------------------------------------------

	/**
		Reset the current state of the simulator
	**/
	public function reset() {
		print( "Reseting the current state" );
		sim.reset();
		println( "\rReseting the current state... Done" );
	}

	/**
		Save the current command log (from the last reset) to `path`
	**/
	public function save( path:String ) {
		print( "Saving the current command log" );
		if ( !reading ) {
			var fout = _writeFile( path, false );
			fout.writeString( sim.log.join(sim.state.newline)+sim.state.newline );
			fout.close();
		}
		println( "\rSaving the current command log... Done" );
	}

	/**
		Execute from a command log in `path`
	**/
	public function restore( path:String ) {
		println( "Reading commands in \""+path+"\"" );
		sim.state.identation++;

		var finp = _readFile( path, true );
		var eof = false;
		_stop = false;
		while ( !eof && !_stop ) {
			try {
				var r = sim.getArgs( finp, sim.state.newline );
				if ( r.length != 0 ) {
					print( "> "+sim.strArgs(r)+baseNewline );
					sim.run( r, true, sim.state.timing, false );
				}
			}
			catch ( e:haxe.io.Eof ) {
				eof = true;
			}
		}
		finp.close();

		sim.state.identation--;
		println( "Reading commands in \""+path+"\"... Done" );
	}

	/**
		Show the current command log
	**/
	public function showLog() {
		println( "Showing the current log" );
		printHL( "-" );
		println( "    :: "+sim.log.join( baseNewline+"    :: " ) ); // log already has newlines
	}



	// MACRO --------------------------------------------------------------------
	// simple preprocessor macros
	// experimental/in development/unstable

	/**
		[EXPERIMENTAL] Define a macro
	**/
	public function define( name:String, expansion:String ) {
		sim.state.macros.set( name, expansion );
	}

	/**
		[EXPERIMENTAL] Define a macro
	**/
	public function undefine( name:String ) {
		sim.state.macros.remove( name );
	}

	/**
		[EXPERIMENTAL] Show defined macros
	**/
	public function showMacros() {
		var names = [ for ( name in sim.state.macros.keys() ) name ];
		names.sort( Reflect.compare );
		println( "  : := :" );
		println( "  :::: := ::" );
		for ( name in names ) {
			println( "  ::"+name+":: := "+sim.state.macros.get( name ) );
		}
	}

	/**
		[EXPERIMENTAL] Preview macro expansion for file in `path`
	**/
	public function expandFile( path:String ) {
		var expanded = _expandFile( path );
		println( expanded );
	}

	private function _expandFile( path:String ):String {
		var macros = sim.state.macros; // just a shortcut
		
		var finp = _readFile( path, true );
		var ibuf = finp.readAll().toString();
		finp.close();

		var obuf = "";
		var r = ~/::(.*?)::/;
		while ( r.match( ibuf ) ) {
			obuf += r.matchedLeft();
			if ( r.matched( 1 ) == null )
				obuf += "::";
			else {
				var name = r.matched( 1 );
				if ( !macros.exists( name ) )
					throw "Unknown macro ::"+name+"::";
				obuf += macros.get( name );
			}
			ibuf = r.matchedRight();
		}
		obuf += ibuf;

		return obuf;
	}

	/**
		[EXPERIMENTAL] Execute a file expanding macros; for now, expansion and
		execution happen in different moments (so macro definitions inside a file
		can only be expanded on subsequent file executions)
	**/
	public function executeFile( path:String ) {
		println( "Expanding macros and reading commands in \""+path+"\"" );
		sim.state.identation++;

		var inp = new StringInput( _expandFile(path) );
		var eof = false;
		_stop = false;
		while ( !eof && !_stop ) {
			try {
				var r = sim.getArgs( inp, sim.state.newline );
				if ( r.length != 0 ) {
					print( ":: "+sim.strArgs(r)+baseNewline );
					sim.run( r, true, true, false );
				}
			}
			catch ( e:haxe.io.Eof ) {
				eof = true;
			}
		}
		inp.close();

		sim.state.identation--;
		println( "Expanding macros and reading commands in \""+path+"\"... Done" );
	}



	// EXECUTION FLOW CONTROL ---------------------------------------------------

	/**
		Stop any loop
	**/
	public function stop() {
		println( "Breaking..." );
		_stop = true;
	}

	/**
		Sleep for `s` seconds
	**/
	public function sleep( s:Float ) {
		println( "Sleeping for "+s+" seconds..." );
		Sys.sleep( s );
		println( "Awake" );
	}



	// TUNING -------------------------------------------------------------------

	/**
		[TUNING] Set heap arity for the internal priority queue used on Dijkstra and A*
	**/
	public function setHeapArity( no:Int ) {
		sim.state.heapArity = no;
		if ( sim.state.digraph != null )
			sim.state.digraph.heapArity = sim.state.heapArity;
		println( "Heap (Dijkstra/A* priority queue) arity set to "+no );
	}

	/**
		[TUNING] Set heap initial reserve for the internal priority queue used on Dijkstra
		and A*
	**/
	public function setHeapReserve( no:Int ) {
		sim.state.heapReserve = no;
		if ( sim.state.digraph != null )
			sim.state.digraph.heapReserve = sim.state.heapReserve;
		println( "Heap (Dijkstra/A* priority queue) initial reserve set to "+no );
	}



	// EXPERIMENTAL -------------------------------------------------------------

	/**
		[EXPERIMENTAL] Set multithreading with `workers` and `part-size`
	**/
	public function setMcpus( workers:Int, partSize:Int ) {
		if ( sim.state.workers != workers || sim.state.workerPartSize != partSize )
			sim.state.invalidate();
		sim.state.workers = workers;
		sim.state.workerPartSize = partSize;
	}

	// ADVANCED -----------------------------------------------------------------

	/**
		[ADVANCED] Set the newline sequence for all file output; options are NL,
		CRNL and NLCR
	**/
	public function setNewline( sequence:String ) {
		switch ( sequence ) {
		case "NL": sim.state.newline = "\n";
		case "CRNL": sim.state.newline = "\r\n";
		case "NLCR": sim.state.newline = "\n\r";
		case all: throw "Unrecognized newline sequence: "+all;
		}
	}

	/**
		[ADVANCED] Peek at the newline sequence for all file output
	**/
	public function showNewline() {
		switch ( sim.state.newline ) {
		case "\n": println( "Current newline sequence is NL" );
		case "\r\n": println( "Current newline sequence is CRNL" );
		case "\n\r": println( "Current newline sequence is NLCR" );
		case all: throw "Something went wrong";
		}
	}

	/**
		[ADVANCED] Set console screen width
	**/
	public function setScreen( columns:Int ) {
		if ( columns < 50 )
			throw "Cannot set the number of columns on the screen to a value bellow 50";
		sim.screenSize = columns;
	}

	/**
		[ADVANCED] Force network and graph assembly; this is
		automaticallly called from --run
	**/
	public function forceAssemble() sim.state.assemble( true );

	/**
		[ADVANCED] Run the unit tests; these are relevant at the moment, since
		they only test the previous graph implementation
	**/
	public function unitTests() {
		println( "Running the unit tests" );
		printHL( "-" );
		var app = new test.unit.UnitTests();
		app.run();
	}

	#if cpp
	/**
		[ADVANCED] Enable the HXCPP internal C++ profiler
	**/
	public function enableProfiling( basePath:String ) {
		sim.profiling = basePath;
	}
	#end

	#if cpp
	/**
		[ADVANCED] Disable the HXCPP internal C++ profiler
	**/
	public function disableProfiling() {
		sim.profiling = null;
	}
	#end

	/**
		[ADVANCED] Enable command execution timing
	**/
	public function enableTiming() {
		sim.state.timing = true;
	}

	/**
		[ADVANCED] Disable command execution timing
	**/
	public function disableTiming() {
		sim.state.timing = false;
	}

	/**
		[ADVANCED] Dump any table in its corresponding ETT; only works if the
		table exists and has at least one record; will overwrite existing files
	**/
	public function dumpEtt( table:String, path:String ) {
		println( "Attempting to dump table \""+table+"\" in \""+path+"\"" );
		var tb:{ iterator:Void->Iterator<Dynamic> } = Reflect.field( sim.state, table );
		if ( tb == null )
			throw "No table";
		if ( !tb.iterator().hasNext() )
			throw "Cannot figure out the type of an EMPTY table";
		var cl:Dynamic = Type.getClass( tb.iterator().next() );
		_genericEtt( path, tb, cl, null, null );
	}

	/**
		[ADVANCED] Query any table of objects, optionally specifying another
		suitable alias table
	**/
	public function justQuery( table:String, type:String, expression:String, ?aliases:String ) {
		var idName = switch ( table ) {
		case "volumes": "linkId";
		case "results": "odId";
		case "speeds": "key";
		case all: "id";
		}
		println( "Attempting to query table \""+table+"\" with '"+expression+"'" );
		var index:Map<Int,Dynamic> = Reflect.field( sim.state, table );
		if ( table == null )
			throw "No table";
		var alias:Map<String,Iterable<Int>> = aliases != null ? Reflect.field( sim.state, aliases ) : null;
		var q = Search.prepare( expression, idName );
		switch ( type.toLowerCase() ) {
		case "show", "list":
			for ( v in q.execute( sim, index, alias ) )
				println( Std.string( v ) );
		case "head":
			var cnt = 0;
			for ( v in q.execute( sim, index, alias ) )
				if ( cnt++ < 20 )
					println( Std.string( v ) );
		case "count":
			println( "Counted "+count( q.execute( sim, index, alias ) )+" records" );
		}
	}

	/**
		[HACK] Windows hack for problems with newlines
	**/
	public function windows() {
		sim.state.newline = "\r\n";
	}



	// OTHERS -------------------------------------------------------------------

	/**
		Show simulator version
	**/
	public function version() {
		println( "Version "+Simulator.COMMIT_HASH );
	}

	/**
		Show simulator version and platform information
	**/
	public function fullVersion() {
		println( "Version "+Simulator.VERSION );
		println( "Git commit "+Simulator.COMMIT_HASH );
		println( 'Built by ${Simulator.BUILD_USERNAME}@${Simulator.BUILD_HOSTNAME} (${Simulator.BUILD_SYSNAME})' );
		println( "Built at "+Date.fromTime(Simulator.BUILD_TIME) );
	}

	/**
		Show coding information
	**/
	public function platform() {
		println( "Platform "+Simulator.PLATFORM+"/"+Sys.systemName() );
	}

	/**
		Show copyright information
	**/
	public function copyright() {
		println( Simulator.COPYRIGHT );
	}

	/**
		Show licensing information
	**/
	public function license() {
		println( Simulator.LICENSE );
	}

	/**
		Powered by ...
	**/
	public function banner() {
		println( "Powered by Haxe and other open-source technologies" );
	}

	/**
		Show information about the software
	**/
	public function welcomeInfo() {
		println( Simulator.FULLNAME );
		copyright();
		license();
		version();
		platform();
		banner();
	}

	/**
		Show more information about the software
	**/
	public function fullInfo() {
		println( Simulator.FULLNAME );
		copyright();
		license();
		fullVersion();
		platform();
		banner();
	}

	/**
		Prints usage information of the available commands; if `pattern` is passed, only commands matching it will
		be listed
	**/
	public function help( ?pattern:String ) {
		var preIdent = sim.state.identation;
		sim.state.identation = 0;
		println( "Usage:" );
		printHL( "-" );
		var args = this.getArguments();
		if ( pattern != null ) {
			var r = new EReg( pattern, "i" );
			var match = function ( arg:mcli.internal.Data.Argument ) return r.match( arg.name );
			args = array( filter( args, match ) );
		}
		Simulator.rawPrint( mcli.Dispatch.showUsageOf( args, sim.screenSize ) );
		sim.state.identation = preIdent;
	}

	/**
		Quit
	**/
	public function quit() {
		if ( sim.online ) {
			state.identation = 0;
			println( "Exiting gracefully" );
			printHL( "=" );
		}
		Sys.exit( 0 );
	}



	// HELPERS ------------------------------------------------------------------

	private function _genericQuery( query:Search, table:Map.IMap<Dynamic,Dynamic>
	, aliases:Null<Map<String,Dynamic>>, type:Null<String>
	, status:Null<String>, notAvailable:Null<String> ) {
		if ( table == null )
			throw notAvailable != null ? notAvailable : "Table not available";
		if ( status != null ) println( status );
		if ( type == null ) type = "count";
		switch ( type.toLowerCase() ) {
		case "show", "list":
			for ( v in query.execute( sim, table, aliases ) )
				println( Std.string( v ) );
		case "head":
			var cnt = 0;
			for ( v in query.execute( sim, table, aliases ) )
				if ( cnt++ < 20 )
					println( Std.string( v ) );
		case "count":
			println( "Counted "+count( query.execute( sim, table, aliases ) )+" records" );
			println( "Pass \"show\" or \"head\" in the optional parameter `type` for more information" );
		}
	}

	private function _genericEtt( path:String, table:Iterable<Dynamic>, cl:Dynamic
	, status:Null<String>, notAvailable:Null<String> ) {
		if ( status != null ) println( status );
		if ( table == null )
			throw notAvailable != null ? notAvailable : "Table not available";
		var eout = _writeEtt( cl, cl.ettFields(), path );
		for ( r in table )
			eout.write( r );
		eout.close();
	}

	private function _odMap( ods:Iterable<OD> ) {
		var map = new Map();
		for ( od in ods )
			map.set( od.id, od );
		return map;
	}

	private function _innerOdQuery( original:Iterable<OD>, type:String, clause:String
	, ?originalFilter:Array<String> ):Null<Iterable<OD>> {
		var c = _readSet( clause );
		if ( c == null )
			return null; // all selected
		var activeOds = original;
		switch ( type ) {
		case "id":
			var f = c.map( parseInt );
			if ( originalFilter != null ) originalFilter.push( "`id` in ("+f.join(",")+")" );
			activeOds = filter( activeOds, function (od) return has(f,od.id) );
		case "lot":
			var f = c.map( parseInt );
			if ( originalFilter != null ) originalFilter.push( "`lot` in ("+f.join(",")+")" );
			activeOds = filter( activeOds, function (od) return has(f,od.lot) );
		case "section", "point", "pt":
			var f = c.map( parseInt );
			if ( originalFilter != null ) originalFilter.push( "`section` in ("+f.join(",")+")" );
			activeOds = filter( activeOds, function (od) return has(f,od.section) );
		case "direction", "dir":
			var f = c.map( parseInt );
			if ( originalFilter != null ) originalFilter.push( "`direction` in ("+f.join(",")+")" );
			activeOds = filter( activeOds, function (od) return has(f,od.direction) );
		case "vehicle", "vehicleId", "veh":
			var f = c.map( parseInt );
			if ( originalFilter != null ) originalFilter.push( "`vehicleId` in ("+f.join(",")+")" );
			activeOds = filter( activeOds, function (od) return has(f,od.vehicleId) );
		case "cargo", "product", "prod":
			if ( originalFilter != null ) originalFilter.push( "`cargo` in ('"+c.join("','")+"'')" );
			activeOds = filter( activeOds, function (od) return has(c,od.cargo) );
		case all: throw "Unknown filter type '"+type+"'";
		}
		return activeOds;
	}

	private function _geojsonNode( node:Node ):String {
		var prop = node.jsonBody();
		var geom = node.geojsonGeometry();
		return '{"id":${node.id},"type":"Feature","geometry":${geom},"properties":{$prop}}';
	}

	private function _geojsonLink( link:Link, speeds:Bool, times:Bool ):String {
		var linkProp = link.jsonBody();
		var geom = _getShape( link ).geojsonGeometry();
		var stateSpeeds = new Map<Int,Array<LinkTypeSpeed>>();
		for ( speed in sim.state.speeds )
			if ( stateSpeeds.exists( speed.typeId ) )
				stateSpeeds.get( speed.typeId ).push( speed );
			else
				stateSpeeds.set( speed.typeId, [ speed ] );
		for ( speedsForType in stateSpeeds )
			speedsForType.sort( function (a,b) return Reflect.compare(a.vehicleId,b.vehicleId) );
		if ( speeds || times ) {
			var speedData = [];
			var timeData = [];
			if ( stateSpeeds.exists( link.typeId ) )
				for ( speed in stateSpeeds.get( link.typeId ) ) {
					if ( speeds )
						speedData.push( '"speed_${speed.vehicleId}":${speed.speed}' );
					if ( times )
						timeData.push( '"time_${speed.vehicleId}":${link.extension/speed.speed}' );
				}
			var ret = '{"id":${link.id},"type":"Feature","geometry":${geom},"properties":{$linkProp';
			if ( speeds )
				ret += ',${speedData.join(",")}';
			if ( times )
				ret += ',${timeData.join(",")}';
			ret += "}}";
			return ret;
		}
		else {
			return '{"id":${link.id},"type":"Feature","geometry":${geom},"properties":{$linkProp}}';
		}
	}

	private function _geojsonVolume( volume:LinkVolume, moreProperties:Null<String> ):String {
		var link = sim.state.links.get( volume.linkId );
		var linkProp = link.jsonBody();
		var linkVolume = volume.jsonBody();
		var geom = _getShape( link ).geojsonGeometry();
		if ( moreProperties != null )
			return '{"id":${link.id},"type":"Feature","geometry":${geom},"properties":{$linkProp,$linkVolume,$moreProperties}}';
		else
			return '{"id":${link.id},"type":"Feature","geometry":${geom},"properties":{$linkProp,$linkVolume}}';
	}

	private function _shp( geojson:String->Null<String>->Void, path:String, filter:Null<String> ) {
		var spath = path+".shp";
		var tpath = path+".json";
		state.identation++;
		geojson( tpath, filter );
		println( "Converting temporary GeoJSON to ESRI Shapefile" );
		for ( p in [ ".shp", ".dbf", ".prj", ".shx" ].map( function (x) return path+x ) )
			if ( sys.FileSystem.exists( p ) )
				if ( sys.FileSystem.isDirectory( p ) )
					throw "Cannot overwrite a folder with a file: \""+p+"\"";
				else {
				 	println( "File \""+p+"\" overwritten" );
				 	FileSystem.deleteFile( p );
				 }
		try {
			var res = Ogr2Ogr.json2shp( spath, tpath, false );
			if ( res == 0 ) {
				println( "Removing temporary GeoJSON" );
				FileSystem.deleteFile( tpath );
			}
			else
				throw "ogr2ogr exited with non zero status `"+res+"`";
		} catch ( e:Dynamic ) {
			println( "ERROR: "+e );
		}
		sim.state.identation--;
	}

	private function _getShape( link:Link):LinkShape {
		var shapes = sim.state.shapes;
		if ( shapes == null )
			sim.state.shapes = shapes = new Map();
		var shp = shapes.get( link.id );
		if ( shp == null )
			shp = _autoLinkShape( link );
		return shp;
	}

	private function _autoLinkShape( link:Link ):LinkShape {
		var nodes = sim.state.nodes;
		if ( nodes == null ) throw "No nodes";
		var pts = [ nodes.get( link.startNodeId ).point, nodes.get( link.finishNodeId ).point ];
		var shp = LinkShape.make( link.id, new format.ett.Geometry.LineString( pts ) );
		sim.state.shapes.set( link.id, shp );
		return shp;
	}

	private function _readEtt( inputPath:String ):ETTReader {
		return new ETTReader( _readFile( inputPath, true ) );
	}

	private function _writeEtt( cl:Class<Dynamic>, fields:Array<ETTField>, outputPath:String ):ETTWriter {
		var fout = _writeFile( outputPath, true );
		var finfo = new format.ett.Data.FileInfo( sim.state.newline, ETTEncoding.UTF8, "\t", "\""
		, Type.getClassName( cl ), fields );
		var w = new ETTWriter( finfo );
		w.prepare( fout );
		return w;
	}

	private function _readFile( inputPath:String, binary:Bool ):FileInput {
		if ( !sys.FileSystem.exists( inputPath ) )
			throw "File \""+inputPath+"\" does not exist";
		if ( sys.FileSystem.isDirectory( inputPath ) )
			throw "Expected a file but found a folder: \""+inputPath+"\"";
		return sys.io.File.read( inputPath, binary );
	}

	private function _writeFile( outputPath:String, binary:Bool ):FileOutput {
		if ( sys.FileSystem.exists( outputPath ) )
			if ( sys.FileSystem.isDirectory( outputPath ) )
				throw "Cannot overwrite a folder with a file: \""+outputPath+"\"";
			else
			 	println( "File \""+outputPath+"\" overwritten" );
		return sys.io.File.write( outputPath, binary );
	}

	private function _right( data:Dynamic, len:Int, ?pad=" " ):String {
		return StringTools.lpad( string( data ), pad, len );
	}

	private function _left( data:Dynamic, len:Int, ?pad=" " ):String {
		return StringTools.rpad( string( data ), pad, len );
	}

	private function _strnum( v:Float, p:Int, len:Int ):String {
		return printDecimal( v, len, p );
	}

	private function _readInt( s:String, ?nullable=true ):Null<Int> {
		return switch ( s.toLowerCase() ) {
		case "", "_", "*", "a", "all": if ( nullable ) null; else throw "Invalid Int "+s;
		case all: parseInt( s );
		};
	}

	private function _readFloat( s:String, ?nullable=true ):Null<Float> {
		if ( s.length > 1 && s.substr( 0, 1 ) == "d" )
			return parseFloat( s.substr(1) );
		else
			switch ( s.toLowerCase() ) {
			case "", "_", "*", "a", "all":
				if ( nullable )
					return null;
				else
					throw "Invalid Float "+s;
			case all:
				return parseFloat( s );
			}
	}

	private function _readBool( s:Null<String>, ?nullable=true ):Null<Bool> {
		if ( s == null )
			if ( nullable ) return true;
			else throw "Boll cannot be null";
		else
			return switch ( s.toLowerCase() ) {
			case "", "_", "*", "a", "all": if ( nullable ) null; else throw "Invalid Bool "+s;
			case "false", "no", "n", "0": false;
			case "true", "yes", "y", "1": true;
			case all: throw "Invalid Bool "+s;
			};
	}

	private static function _readSet( s:Null<String>, ?nullable=true ):Null<Array<String>> {
		if ( s == null )
			if ( nullable ) return null;
			else throw "Set cannot be null";
		else
			return switch ( s.toLowerCase() ) {
			case "", "_", "*": null; if ( nullable ) null; else throw "Invalid String "+s;
			case all: s.split( "," );
			};
	}

}
