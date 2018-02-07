# this code is used to download RS images from Google Earth Engine (GEE) without clicking "run" button for each image in the GEE website
# it is a python version ported from a javascript version and need open and log in the GEE when running this code in a python envrionment like Anaconda

# -*- coding: utf-8 -*-
import ee
#import MapClient

ee.Initialize()

def exportROIimages(featurePoint,number):
    #Define ROI by creating a rectangle around the marker point 
    rectangle = ee.Feature(featurePoint.buffer(20000).bounds());
    roi = rectangle.geometry()
   
    roi_geometry = roi.getInfo()['coordinates']
    
    #Display ROI
    #MapClient.addToMap(roi)
    
    #Load Sentinel-1 and Sentinel-2 image collections
    coll_s1 = ee.ImageCollection('COPERNICUS/S1_GRD');
    coll_s2 = ee.ImageCollection("COPERNICUS/S2");
    
    #Filter Sentinel-1 collection for ROI and instrument mode. 
    #Keep only 10 most recent images
    coll_s1_filtered = coll_s1.filterBounds(roi).filter(ee.Filter.listContains('transmitterReceiverPolarisation', 'VV')).filter(ee.Filter.eq('instrumentMode', 'IW')).sort('system:time_start',None).limit(3);

    #Filter Sentinel-2 collection for ROI and cloud-coverage.
    #Keep only 10 most recent images with less than 5% clouds
    coll_s2_filtered = coll_s2.filterBounds(roi).filter(ee.Filter.lte('CLOUDY_PIXEL_PERCENTAGE', 5)).sort('system:time_start',None).limit(3);
           
    #Create Sentinel-1 temporal mean map composite of VV amplitude                 
    s1_mean = coll_s1_filtered.reduce(ee.Reducer.mean()).select(['VV_mean'])
    #Create Sentinel-2 temporal median composite as RGB image
    s2_median = coll_s2_filtered.reduce(ee.Reducer.median()).select(['B4_median','B3_median','B2_median'])


    #Export Sentinel-1 temporal mean map composite image to disk, pixel spacing 10m
    task_config = {
    'description': 'Sentinel1_' + str(number),
    'scale': 10,  
    'region': roi_geometry
    }

    task = ee.batch.Export.image(s1_mean, 's1_mean %d' % number, task_config)

    task.start()
    
    #Export Sentinel-2 temporal median RGB composite image to disk, pixel spacing 10m  
    task_config = {
    'description': 'Sentinel2_' + str(number),
    'scale': 10,  
    'region': roi_geometry
    }

    task = ee.batch.Export.image(s2_median, 's2_median %d' % number, task_config)

    task.start()
    
    return 1;
    

listOfMarkers = ee.FeatureCollection([ee.Feature(ee.Geometry.Point([6.8115234375, 60.88836817267309]),{"system:index": "0"}),ee.Feature(ee.Geometry.Point([15.1611328125, 57.469327688204295]),{"system:index": "1"}),ee.Feature(ee.Geometry.Point([27.0703125, 62.95584745563692]),{"system:index": "2"})]);
listOfMarkers = listOfMarkers.sort('system:index')
#Convert FeatureCollection of marker points to list; 
#maximum number of markers is 100
listOfMarkersList = listOfMarkers.toList(100)
numberOfMarkers = listOfMarkersList.size().getInfo()

#Loop through list of markers for export of the individual ROIs
i = 0
while (i < numberOfMarkers):
    exportROIimages(ee.Feature(listOfMarkersList.get(i)),i)
    i += 1

    
