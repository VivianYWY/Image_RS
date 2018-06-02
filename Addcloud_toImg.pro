;This code is used to add simulated cloud mask to the 1-10 bands of cloudless sentinel-2 image in a batch mode, finally get cloudy sentinel-2 image,leave the last band unadded cloud
;simulated cloud mask is 8 bit (0-255) png, thus need to transfer to 16 bit (0-65535) at first
;cloudless sentinel-2 image have 11 bands (rather than normally 13 bands)
; 1-10 bands are b2,b3,b4,b5,b6,b7,b8,b8a,b11,b12, the last band is the HV image from co-registered sentinel-1 image
;for both cloud mask and cloudless image, they have the same size (256*256),namely patches

;when runing this code, the ENVI window and toolbar should be opened

pro AddCloudToImage    
  ; Firstrestore all the base save files.
  COMPILE_OPT IDL2
   e = envi()
  ;Initialize ENVI and send all errors
  ; andwarnings to the file batch.txt
  envi_batch_init, log_file='batch.txt'
  
  ;store the file name of the cloud mask in batch
  cd,'E:\RS\all_patches\train\1\'
  CloudMask = FILE_Search("*.png")
  MaskCount = N_ELEMENTS(CloudMask)
  IF MaskCount EQ 0 THEN RETURN
  
  ;store the file name of the cloudless img in batch
  cd,'E:\RS\all_patches\train\2\'
  Cloudless = FILE_Search("*.dat")
 
  ;loop for one cloud mask and corresponding cloudless patch
  FOR NX = 0,MaskCount -1 DO BEGIN
    CloudFileName = CloudMask[NX]
    Cloud_path = FILEPATH(CloudFileName,ROOT_DIR = 'E:\RS',SUBDIRECTORY = ['all_patches','train','1'])
    
    PatchFileName = Cloudless[NX]
    Patch_path = FILEPATH(PatchFileName,ROOT_DIR = 'E:\RS',SUBDIRECTORY = ['all_patches','train','2'])
    
    CloudFileName_16bit = PatchFileName
    Cloud_path_16bit = FILEPATH(CloudFileName_16bit,ROOT_DIR = 'E:\RS',SUBDIRECTORY = ['all_patches','train','E'])
    
    OutFileName = PatchFileName
    Out_path = FILEPATH(OutFileName,ROOT_DIR = 'E:\RS',SUBDIRECTORY = ['all_patches','train','D'])
     
  
     ;load the cloud mask and cloudless patch
     ;open ENVI type file '.dat'
     input_Patch = e.OpenRaster(Patch_path)
     
    
    ;open external file type 'png'
     input_Cloud = e.OpenRaster(Cloud_path,EXTERNAL_TYPE='png') 
        
    ;Set up output raster to be the same as the input input_raster 
    ;including number of bands. Specifically, we need
    ;the spatial reference to be the same
     output_raster = e.CreateRaster(URI = Out_path, input_Patch,$
        NROWS=input_Patch.NROWS, $
        NCOLUMNS=input_Patch.NCOLUMNS, $
        NBANDS=11, $
        DATA_TYPE=12, $
        SPATIALREF=input_Patch.spatialref)
        
     ;get all spectral data from patch 
     all_bands = input_Patch.GetData()
     cloud_bands = input_Cloud.GetData()
     
     output_Cloud = e.CreateRaster(URI = Cloud_path_16bit,all_bands[*,*,0],$
        NROWS=input_Cloud.NROWS, $
        NCOLUMNS=input_Cloud.NCOLUMNS, $
        NBANDS=1, $
        DATA_TYPE=12);pay attention to the "DATA_TYPE",here "12" means "unsigned integer", namely, 16bit
        
     c1 = cloud_bands[*,*,0]
     ;band math
     c2 = uint(c1)*uint(255) ;pay attention to "uint", without it, the default will be 8-bit value
     output_Cloud.SetData, c2
     output_Cloud.Save
     
     ;loop for ten bands
     FOR N =0,9 Do BEGIN
       b1 = all_bands[*,*,N]
       b2 = c2
       ;do the band math
       data = uint(b2 * 0.01 + b1 * 0.99) ;when doing alpha blending, the coefficients alpha and (1-alpha) will decide the opaque degree of these two images when overlap 
       ;if the gray value range of these two images have much difference, pay attention to the choice of coefficients
       output_raster.SetData, data, BANDS=[N]
     ENDFOR
       output_raster.SetData, all_bands[*,*,10], BANDS=[10]
       output_raster.Save
       ;save data to the output raster
     ENDFOR
end
       
     
    
  
  
