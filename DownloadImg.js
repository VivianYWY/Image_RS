//////////////////////////////////////step 1: date and roi should be set
//filter parameter
var startDate = '2017-03-01';
var endDate = '2017-05-31';
// in the end our ROI is defined by kml, that I send you. 
//You can transfer each kml to fusion table and get its ID, to used here.
var roi = ee.FeatureCollection('ft:1asTMfU114YQdhsURKvCJz9_tzK4PpxFxPhx0H1iY') ; //attention: ft is not part of the ID 
print(roi); //by printing ROI, we can see the coordinates directly in console, and then copy and paste them in the following line 


//////////////////////////////////////step 2: nothing should be changed unless you talk with me if necessary

var bands = ee.List([ 'B2', 'B3', 'B4', 'B8', 'B11']) ;
//only b11 is 20m, this lead to the related index resolution is also 20

//this is the Sentinel 2 data in GEE
var Data_s2 = ee.ImageCollection("COPERNICUS/S2");

//This is the cloud percentage threshold to choose image, not very important since will will combine the image later
var maxCloudPercentage = 20 ;
 
// cloudMask
function cloudMask(im) {
  // Opaque and cirrus cloud masks cause bits 10 and 11 in QA60 to be set,
  // so values less than 1024 are cloud-free
  var mask = ee.Image(0).where(im.select('QA60').gte(1024), 1).not();
  return im.updateMask(mask);
}
 
//Filter almost cloud-free images of this year
var filter_1 = Data_s2.filterDate(startDate, endDate)
                      .filterBounds(roi)
                      .filter(ee.Filter.lessThanOrEquals('CLOUDY_PIXEL_PERCENTAGE', maxCloudPercentage))
                      .map(cloudMask);
 
print(filter_1.size());

var colList = filter_1.toList(500);
var n = colList.size().getInfo();
var first = ee.List(['ImageID']);
//download these cloud-free images
for (var i = 0; i < n; i++) {
      var img = ee.Image(colList.get(i));
      var id = img.id().getInfo();
      first = first.add(id);
      
      Export.image.toDrive({
  image: img,
  description: 'HongKong_'+ (i),
  scale: 10,
  region: roi
  });
          
    }
//export the ImageID list of these cloud-free images
print(first);
//Export.table.toDrive(first);
    