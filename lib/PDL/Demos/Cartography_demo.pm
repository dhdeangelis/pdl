package PDL::Demos::Cartography_demo;

sub init {'
use PDL::Transform::Cartography;
'}
sub done {'
undef $w;
'}

sub info {('cartography','Cartographic projections (Req.: PDL::Graphics::Simple)')}

my @demos = (
PDL->rpiccan('JPEG') ? () :
    [comment => q|
This demo illustrates the PDL::Transform::Cartography module.  

It requires PDL::Graphics::Simple and also the ability to read/write
JPEG images.

You don't seem to have that ability at the moment -- this is likely
because you do not have NetPBM installed.  See the man page for PDL::IO::Pic.

I'll continue with the demo anyway, but it will likely crash on the 
earth_image('day') call on the next screen.

|],

[comment => q|

 This demo illustrates the PDL::Transform::Cartography module.
 Also you must have PDL::Graphics::Simple installed to run it.

 PDL::Transform::Cartography includes a global earth vector coastline map
 and night and day world image maps, as well as the infrastructure for 
 transforming them to different coordinate systems.
|],

[act => q|
  ### Load the necessary modules 
    use PDL::Graphics::Simple;
    use PDL::Transform::Cartography;
    
  ### Get the vector coastline map (and a lon/lat grid), and load the Earth
  ### RGB daytime image -- both of these are built-in to the module. The
  ### coastline map is a set of (X,Y,Pen) vectors.
    $coast = earth_coast()->glue( 1, scalar graticule(15,1) );
    print "Coastline data are a collection of vectors:  ",
             join("x",$coast->dims),"\n";

    $map = earth_image('day');
    print "Map data are RGB:   ",join("x",$map->dims),"\n\n";
|],

[act => q&
  ### Map data are stored natively in Plate Carree format.
  ### The image contains a FITS header that contains coordinate system info.
  print "FITS HEADER INFORMATION:\n";
  for $_(sort keys %{$map->hdr}){
    next if(m/SIMPLE/ || m/HISTORY/ || m/COMMENT/);
    printf ("  %8s: %10s%s", $_, $map->hdr->{$_}, (++$i%3) ? "  " : "\n"); 
  }
  print "\n";

  $w = pgswin();
  $w->plot(with=>'fits', $map, {Title=>"NASA/MODIS Earth Map (Plate Carree)",J=>0});
&],

[act => q&
  ### The map data are co-aligned with the vector data, which can be drawn
  ### on top of the window with the "with polylines" PDL::Graphics::Simple
  ### plot type.  The clean_lines method breaks lines that pass over
  ### the map's singularity at the 180th parallel.
  
  $w->hold;
  $w->plot(with=>'polylines', $coast->clean_lines);
  $w->release;

&],

[act => q&
### There are a large number of map projections -- to list them all, 
### say "??cartography" in the perldl shell.  Here are four
### of them:

undef $w; # Close old window
$w = pgswin( size=>[8,6], multi=>[2,2] ) ;

sub draw {
 ($tx, $t, $px, @opt ) = @_;
 $w->plot(with=>'fits', $map->map( $tx, $px, @opt ),
   with=>'polylines', $coast->apply( $tx )->clean_lines(@opt),
   {Title=>$t, J=>1});
}

## (The "or" option specifies the output range of the mapping)
draw( t_mercator,  "Mercator Projection",    [400,300] );
draw( t_aitoff,    "Aitoff / Hammer",        [400,300] );
draw( t_gnomonic,  "Gnomonic",               [400,300],{or=>[[-3,3],[-2,2]]} );
draw( t_lambert,   "Lambert Conformal Conic",[400,300],{or=>[[-3,3],[-2,2]]} );
&],

[act => q|
### You can create oblique projections by feeding in a different origin.
### Here, the origin is centered over North America.

draw( t_mercator(  o=>[-90,40] ), "Mercator Projection",    [400,300] );
draw( t_aitoff (   o=>[-90,40] ), "Aitoff / Hammer",        [400,300] );
draw( t_gnomonic(  o=>[-90,40] ), "Gnomonic",[400,300],{or=>[[-3,3],[-2,2]]} );
draw( t_lambert(   o=>[-90,40] ), "Lambert ",[400,300],{or=>[[-3,3],[-2,2]]} );

|],

[act => q|
### There are three main perspective projections (in addition to special
### cases like stereographic and gnomonic projection): orthographic,
### vertical, and true perspective.  The true perspective has options for
### both downward-looking and aerial-view coordinate systems.

draw( t_orthographic( o=>[-90,40] ), 
      "Orthographic",  [400,300]);

draw( t_vertical( r0=> (2 + 1), o=>[-90,40] ), 
      "Vertical (Altitude = 2 r_e)", [400,300]);

draw( t_perspective( r0=> (2 + 1), o=>[-90,40] ),
      "True Perspective (Altitude= 2 r_e)", [400,300]);

# Observer is 0.1 earth-radii above surface, lon 117W, lat 31N (over Tijuana).
# view is 45 degrees below horizontal, azimuth -22 (338) degrees.
draw( t_perspective( r0=> 1.1, o=>[-117,31], cam=>[-22,-45,0] ),
      "Aerial view of West Coast of USA", [400,300],
      {or=>[[-60,60],[-45,45]], method=>'linear'});

|],

[comment => q|

That concludes the basic cartography demo.  Numerous other transforms
are available.  

Because PDL's cartographic transforms work within the Transform module
and are invertible, it's easy to use them both forwards and backwards.
In particular, the perspective transformation is useful for ingesting 
scientific image data of the Earth or other planets, and converting to
a map of the imaged body.

Similarly, scanned images of map data can easily be converted into 
lat/lon coordinates or reprojected to make other projections. 

|],
);

sub demo { @demos }

1;
