////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//PV 2021Oct15
//measuring mucus layer thickness
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//Variables use in macro

//these are default files used for testing. they will be superceded by users choice if that is enabled
OpenFileVar1="C:/Users/praju vikas/Desktop/Image Analysis Workflows/Daping/beads.tif";	OpenFileVar2="C:/Users/praju vikas/Desktop/Image Analysis Workflows/Daping/tissue.tif";
//OpenFileVar1="C:/Users/praju vikas/Desktop/Image Analysis Workflows/Daping/beads L.tif";	OpenFileVar2="C:/Users/praju vikas/Desktop/Image Analysis Workflows/Daping/tissue L.tif";

//tissue processing parameters
//for smotthing 
TissueMedn=5;		TissueGaus=20;

//for thresholding
TissueThresholdMin=15;		TissueThresholdMax=300;

//tissue processing parameters
//for smotthing and DoG
BeadsMedn=2;		BeadsGaus01=1;		BeadsGaus02=4;

//for thresholding
BeadsThresholdMin=40;		BeadsThresholdMax=300;

//for filtering
BeadsSizeMin=3;
BeadExclusionZone=30;

//in some instances the images were acquired 'upisde down'. to reverse order enter Yes
TopBottomArray=newArray( "Bottom","Top");
TopFirst="Bottom";

RescaleYAxis=1;

Troubleshooting=1;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//code starts here

////////////////////
//std initialise macro. also gets macro start time for ref
run("Close All");		run("Clear Results");		roiManager("reset");		run("Set Measurements...", "fit redirect=None decimal=0");
if (isOpen("Log")) { selectWindow("Log"); run("Close");};		if (isOpen("Summary")) { selectWindow("Summary"); run("Close");};
getDateAndTime(StartYear, StartMonth, StartDayOfWeek, StartDayOfMonth, StartHour, StartMinute, StartSecond, StartMsec);
//exit;

////////////////////
//Edit analysis parameters
	Dialog.create("Edit the analysis parameters here");		
	Dialog.addMessage("Edit the analysis parameters below\n");	

	Dialog.addMessage("\n");	
	Dialog.addMessage("Tissue Smoothing");	
	Dialog.addNumber("Median", TissueMedn);
	Dialog.addNumber ("Gaussian",TissueGaus);

	Dialog.addMessage("\n");	
	Dialog.addMessage("Beads Processing");	
	Dialog.addNumber("Median", BeadsMedn);
	Dialog.addNumber ("Lower Gaussian",BeadsGaus01);
	Dialog.addNumber ("Higher Gaussian",BeadsGaus02);

	Dialog.addMessage("\n");	
	Dialog.addMessage("Manual Threshold Values");	
	Dialog.addNumber("Tissue Threshold Minimum ", TissueThresholdMin);
	Dialog.addNumber("Tissue Threshold Maximum ",TissueThresholdMax);
	Dialog.addNumber("Beads Threshold Minimum ", BeadsThresholdMin);
	Dialog.addNumber("Beads Threshold Maximum ",BeadsThresholdMax);

	Dialog.addMessage("\n");	
	Dialog.addMessage("Bead Filtering");	
	Dialog.addNumber("Beads Size Minimum ", BeadsSizeMin);
	Dialog.addNumber("Beads Exclusion Diameter",BeadExclusionZone);

	Dialog.addMessage("\n");	
	Dialog.addChoice("Tissue at Top or Bottom?", TopBottomArray);

	Dialog.show();

	TissueMedn=Dialog.getNumber();
	TissueGaus=Dialog.getNumber();

	BeadsMedn=Dialog.getNumber();
	BeadsGaus01=Dialog.getNumber();
	BeadsGaus02=Dialog.getNumber();

	TissueThresholdMin=Dialog.getNumber();
	TissueThresholdMax=Dialog.getNumber();

	BeadsThresholdMin=Dialog.getNumber();
	BeadsThresholdMax=Dialog.getNumber();

	BeadsSizeMin=Dialog.getNumber();
	BeadExclusionZone=Dialog.getNumber();

	TopFirst=Dialog.getChoice();
//exit

////////////////////
//open files
OpenFileVar2= File.openDialog("Select Tissue image File for analysis"); 	
OpenFileVar1= File.openDialog("Select Beads image File for analysis"); 	

run("Bio-Formats Importer", "open=OpenFileVar1 color_mode=Default rois_import=[ROI manager] split_channels view=[Standard ImageJ] stack_order=Default");
BeadsOriginalName=substring(OpenFileVar1, lastIndexOf(OpenFileVar1, "\\")+1, lastIndexOf(OpenFileVar1,"."));
rename("beads");

run("Bio-Formats Importer", "open=OpenFileVar2 color_mode=Default rois_import=[ROI manager] split_channels view=[Standard ImageJ] stack_order=Default");
TissueOriginalName=substring(OpenFileVar2, lastIndexOf(OpenFileVar2, "\\")+1, lastIndexOf(OpenFileVar2,"."));
rename("tissue");
//print (BeadsOriginalName+" | "+TissueOriginalName);
//exit

////////////////////////////////////////////////////////////////////////////////
//Bead image processing and Segmentation

selectWindow("beads");

//image acquisition was either top to bottom or bottom to top. so toggle 
if (TopFirst=="Top")	{run("Reverse");};


//exit

//obtain image dimensions. used for reslicing
getDimensions(BeadsWidth, BeadsHeight, BeadsChannels, BeadsSlices, BeadsFrames);	
NewHeight=RescaleYAxis*BeadsSlices;

//smooth image and DoG to sharpen beads
selectWindow("beads");	
run("Median...", "radius=BeadsMedn stack");

selectWindow("beads");		run("Duplicate...", "title=beadsGaus01 duplicate");
run("Gaussian Blur...", "sigma=BeadsGaus01 stack");

selectWindow("beads");		run("Duplicate...", "title=beadsGaus02 duplicate");
run("Gaussian Blur...", "sigma=BeadsGaus02 stack");

imageCalculator("Subtract create stack", "beadsGaus01","beadsGaus02");
rename("beadsTopHat");

//clean up
if (Troubleshooting==1)		
	{	close("beadsGaus01");		close("beadsGaus02");	}
//exit

//Threshold beads
selectWindow("beadsTopHat");
setThreshold(BeadsThresholdMin, BeadsThresholdMax);		run("Convert to Mask", "method=Yen background=Dark black");
//exit

//remove stacked beads above the selected beads in lower layer. 
//iterate through whole stack

//duplicate stack for processing
selectWindow("beadsTopHat");		run("Duplicate...", "title=TempBeadStk duplicate");		run("Duplicate...", "title=beadsTopHatOriginal duplicate");
for (i=1; i<=BeadsSlices; i++)
	{	
	selectWindow("TempBeadStk");
	setSlice(i);		

	run("Duplicate...", " ");		
	rename("Temp");

	//filter small bits out. this varis set at teh begining
	RunVar="area="+BeadsSizeMin+"-Infinity black_background";
	run("Shape Filter", RunVar);
	//"area=3-Infinity area_convex_hull=0-Infinity perimeter=0-Infinity perimeter_convex_hull=0-Infinity feret_diameter=0-Infinity min._feret_diameter=0-Infinity max._inscr._circle_diameter=0-Infinity area_eq._circle_diameter=0-Infinity long_side_min._bounding_rect.=0-Infinity short_side_min._bounding_rect.=0-Infinity aspect_ratio=1-Infinity area_to_perimeter_ratio=0-Infinity circularity=0-Infinity elongation=0-1 convexity=0-1 solidity=0-1 num._of_holes=0-Infinity thinnes_ratio=0-1 contour_temperatur=0-1 orientation=0-180 fractal_box_dimension=0-2 option->box-sizes=2,3,4,6,8,12,16,32,64 black_background");
	
	//Dilate bead by user defined amt
	run("Duplicate...", "title=TempDil");			run("Options...", "iterations=BeadExclusionZone count=3 black do=Dilate");
	imageCalculator("Subtract create stack", "TempBeadStk","TempDil");

	//replace this new slice back into original stack
	selectWindow("Temp");	run("Select All");	run("Copy");
	selectWindow("beadsTopHat");	setSlice(i);	run("Paste");

	//cleanup
	close("Temp");	close("TempDil");	close("TempBeadStk");
	selectWindow("Result of TempBeadStk");	rename("TempBeadStk");
	}

close("TempBeadStk");
 
if (Troubleshooting==1)		
	{	close("beadsTopHatOriginal ");		}

//Filter beads by size
selectWindow("beadsTopHat");
run("Analyze Particles...", "size=BeadsSizeMin-Infinity show=Masks stack");		run("Invert LUT");
rename("beadsTopHatFiltered");

//Ultimate erode to find centeroid
selectWindow("beadsTopHatFiltered");
run("Ultimate Points", "stack");
setThreshold(1, 255);		run("Convert to Mask", "method=Yen background=Dark black");
 
selectWindow("beadsTopHatFiltered");
run("Z Project...", "projection=[Max Intensity]");
rename("beadsTopHatFilteredMaxProject");

//Orthoganal view and stretch - strecth is optional
//Top
selectWindow("beadsTopHatFiltered");
run("Reslice [/]...", "output=1 start=Top avoid");		rename("beadsTopHatFilteredResliceTop");
//RunVar="x=1.0 y="+RescaleYAxis+" z=1.0 width="+BeadsWidth+" height="+NewHeight+" depth=344 interpolation=None process create";		run("Scale...", RunVar);
rename("beadsOrthoTop");

//left side ||| better to get distance from 2 sides and then avg to get better representation
selectWindow("beadsTopHatFiltered");
run("Reslice [/]...", "output=1 start=Left avoid");		rename("beadsTopHatFilteredResliceLeft");
//RunVar="x=1.0 y="+RescaleYAxis+" z=1.0 width="+BeadsWidth+" height="+NewHeight+" depth=344 interpolation=None process create";		run("Scale...", RunVar);
rename("beadsOrthoLeft");
//exit

//cleanup
if (Troubleshooting==1)		
	{	close("beadsTopHatFilteredResliceLeft");
		close("beadsTopHatFilteredResliceTop");
		close("beadsTopHatFiltered");
		close("beadsTopHat");
		close("beads");
	}
//exit

////////////////////////////////////////////////////////////////////////////////
//Tissue image processing and Segmentation

selectWindow("tissue");

//image acquisition was either top to bottom or bottom to top. so toggle 
if (TopFirst=="Yes")	{run("Reverse");};

//exit

//obtain image dimensions. used for reslicing
getDimensions(TissueWidth, TissueHeight, TissueChannels, TissueSlices, TissueFrames);	
NewHeight=RescaleYAxis*TissueSlices;

//smooth image
run("Median...", "radius=TissueMedn stack");
run("Gaussian Blur...", "sigma=TissueGaus stack");

//Orthoganal view and stretch - strecth is optional
//Top
selectWindow("tissue");
run("Reslice [/]...", "output=1 start=Top avoid");		rename("TissueResliceTop");
//RunVar="x=1.0 y="+RescaleYAxis+" z=1.0 width=344 height="+NewHeight+" depth=344 interpolation=Bilinear process create";		run("Scale...", RunVar);
setThreshold(TissueThresholdMin, TissueThresholdMax);		run("Convert to Mask", "method=Yen background=Dark black");		
rename("TissueOrthoTop");

//left side ||| better to get distance from 2 sides and then avg to get better representation
selectWindow("tissue");
run("Reslice [/]...", "output=1 start=Left avoid");		rename("TissueResliceLeft");
//RunVar="x=1.0 y="+RescaleYAxis+" z=1.0 width=344 height="+NewHeight+" depth=344 interpolation=Bilinear process create";		run("Scale...", RunVar);
setThreshold(TissueThresholdMin, TissueThresholdMax);		run("Convert to Mask", "method=Yen background=Dark black");
rename("TissueOrthoLeft");

//clean up
if (Troubleshooting==1)		
	{	close("TissueResliceLeft");				close("tissue");				close("TissueResliceTop");
	}

////////////////////////////////////////////////////////////////////////////////
//Eucledian distance mapping of tissue inverted. to identify distance from background to tissue
selectWindow("TissueOrthoLeft");		run("Duplicate...", "title=TissueOrthoLeftEDM duplicate");
run("Invert", "stack");		run("Distance Map", "stack");		

selectWindow("TissueOrthoTop");		run("Duplicate...", "title=TissueOrthoTopEDM duplicate");
run("Invert", "stack");		run("Distance Map", "stack");		
 
//take 8 bit mask and reduce to 1or 0. this be multiplied with EDM to identify height
selectWindow("beadsOrthoTop");		run("Duplicate...", "title=beadsOrthoTopNormalized duplicate");
run("Divide...", "value=255 stack");
imageCalculator("Multiply create stack", "beadsOrthoTopNormalized","TissueOrthoTopEDM");
rename("beadsOrthoTopEDM");

selectWindow("beadsOrthoLeft");		run("Duplicate...", "title=beadsOrthoLeftNormalized duplicate");
run("Divide...", "value=255 stack");
imageCalculator("Multiply create stack", "beadsOrthoLeftNormalized","TissueOrthoLeftEDM");
rename("beadsOrthoLeftEDM");

run("Merge Channels...", "c1=beadsOrthoTop c2=TissueOrthoTop keep");
rename("Tissue Green Bead Red");

//clean up
if (Troubleshooting==1)		
	{	
		close("beadsOrthoLeft");	
		close("beadsOrthoLeftNormalized");
		//close("beadsOrthoTop");	
		close("beadsOrthoTopNormalized");
		//close("TissueOrthoTop");	
		close("TissueOrthoTopEDM");
		close("TissueOrthoLeft");	
		close("TissueOrthoLeftEDM");
	}

////////////////////////////////////////////////////////////////////////////////
//Remapping ortho to X Y

//start with top orth reslice and now that inetnsities are plane position we can project the images down and analyse it all as 1 image
selectWindow("beadsOrthoTopEDM");
run("Reslice [/]...", "output=1 start=Top avoid");
run("Z Project...", "projection=[Max Intensity]");
rename("beadsOrthoTopEDMZProject");

//start with left orth reslice and now that inetnsities are plane position we can project the images down and analyse it all as 1 image
selectWindow("beadsOrthoLeftEDM");
run("Reslice [/]...", "output=1 start=Top rotate avoid");
run("Z Project...", "projection=[Max Intensity]");
rename("beadsOrthoLeftEDMZProject");

//Analyze all the spots and display results
selectWindow("beadsTopHatFilteredMaxProject");
rename(BeadsOriginalName+"Top");
run("Set Measurements...", "area centroid integrated redirect=[beadsOrthoTopEDMZProject] decimal=5");
run("Analyze Particles...", "size=0-Infinity display summarize");
rename(BeadsOriginalName+"Left");
run("Set Measurements...", "area centroid integrated redirect=[beadsOrthoLeftEDMZProject] decimal=5");
run("Analyze Particles...", "size=0-Infinity display summarize");

//clean up
if (Troubleshooting==1)		
	{	close("beadsTopHatFilteredMaxProject");
		close("beadsOrthoTopEDM");
		close("beadsOrthoLeftEDM");
		close("Reslice of beadsOrthoTopEDM");
		//close("beadsOrthoTopEDMZProject");
		close("beadsOrthoTopEDMZProjectMask");
		close("Reslice of beadsOrthoLeftEDM");
		//close("beadsOrthoLeftEDMZProject");
		close("beadsOrthoLeftEDMZProjectMask");
		//run("Close All");
		close("beadsTopHatOriginal");
		close(BeadsOriginalName+"Top");
	}

selectWindow("beadsOrthoTopEDMZProject");		run("royal");		run("Enhance Contrast", "saturated=0");
run("Maximum...", "radius=2");

selectWindow("beadsOrthoLeftEDMZProject");		run("royal");		run("Enhance Contrast", "saturated=0");
run("Maximum...", "radius=2");

selectWindow("beadsOrthoTop");			run("Reslice [/]...", "output=1 start=Top avoid");
getDimensions(TissueWidth, TissueHeight, TissueChannels, TissueSlices, TissueFrames);	
RunVar="lut=royal start=1 end="+TissueSlices;
run("Temporal-Color Code", RunVar);
rename("beads Height ColourCoded");
run("Maximum...", "radius=2");

selectWindow("TissueOrthoTop");			run("Reslice [/]...", "output=1 start=Top avoid");
RunVar="lut=royal start=1 end="+TissueSlices+" create";
run("Temporal-Color Code", RunVar);
//selectWindow("MAX_colored");
//rename("Tissue Height ColourCoded");


close("beadsOrthoTop");
close("TissueOrthoTop");
close("Reslice of beadsOrthoTop");
close("Reslice of TissueOrthoTop");

