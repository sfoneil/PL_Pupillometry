# PL_Pupillometry
Analysis pipeline for pupilometry data

## Files:

  `et_main_analysis.m` - main program for running analysis
    
   `et_start.m` - helper for finding subject files in \Results_data\ and loading, calls et_main_analysis()

---

\subfunctions\ - below functions

   ### Functions for segmenting data
   `et_segment.m`
  
   `et_segmentbl.m`
  
   `et_truncseg.m`
  

   ### Functions for averaging trials that are segmented
  
   `et_average.m`
  
   `et_blaverage.m`
  

   ### Plotting
  
   `et_plotavg.m`
  
   `et_plotraw.m`
  
   `et_plotseg.m`
  
   ### Helper functions
  
   `et_movedata.m` - Find and move PL exports and marker data to same location for processing.
   
   `et_findshortesttrial.m`
  
  `et_rescaleX.m`

  ---
  \Results_data\ - subject files

  ---

  \Plots\ - created .png plots
