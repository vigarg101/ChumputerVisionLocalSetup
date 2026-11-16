This Repo contains the folder structure, batch file, and low storage files needed to support the local version of the Chumputer Vision application. 

To get started:  
  1. Download the repository contents as a ZIP file
  2. Extract the ZIP file
  3. Download the supporting files from the GCP bucket: https://console.cloud.google.com/storage/browser/chumputer_models;tab=objects?forceOnBucketsSortingFiltering=true&chat=true&project=project-00957900-f91a-4d04-934&prefix=&forceOnObjectsSortingFiltering=false
     The files required for download are:
       - chumputer_bundle.tar
       - chumputer_models/NASNetLarge_SAM_model_file.hdf5
       - chumputer_models/ConvNeXtLarge_SAM_model_file.hdf5
       - chumputer_models/effnetv2l_SAM_model_file.hdf5
       - chumputer_models/Scalevision/crop_vision/sam_vit_h_4b8939.pth
    
  4. Locate the extracted ZIP folder in your file browser and add the following files to match this folder structure:

   ```  
     C:.
      │   .loaded_stamp
      │   chumputer_bundle.tar
      │   run_chumputer.bat
      │   chumputer_user_guide.pdf
      │
      └───opt
          └───chumputer 
              │   ConvNeXtLargeSAM_SGD_history.pkl
              │   ConvNeXtLarge_SAM_model_file.hdf5
              │   effnetv2lhistory_2.pkl
              │   effnetv2lhistory_history2.pkl
              │   effnetv2l_SAM_model_file.hdf5
              │   NASNetLarge_SAM_model_file.hdf5
              │
              └───Scalevision
                  └───crop_vision
                          mask_weights.pth
                          sam_vit_h_4b8939.pth
                          target_feats.pth
                          weights.pth
  ```

  6. Once you have verified that the files in the folder match the folder and file structure above, you can start annotating and labeling.


There is a full user guide that will explain the app features and provide more detailed instructions for the setup. 
