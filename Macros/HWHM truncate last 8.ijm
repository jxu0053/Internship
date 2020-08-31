/*
 * Macro template to process multiple images in a folder
*/

//PROMPT USER for input folder, output folder, and image extension
#@ File (label = "Input directory", style = "directory") input
#@ String (label = "File suffix", value = ".tiff") suffix

processFolder(input);

function processFolder(input) {
/* function to scan folders/subfolders/files to process files with correct suffix */
	list = getFileList(input);
	list = Array.sort(list);

	//pritns stuff to track
	print("FILE LIST :");
	Array.print(list);

	//Loop through files and subfolders to apply process
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix)) {
			//print("IMAGE: ", list[i]);
			processFile(input, list[i]);
		}
		else if(File.isDirectory(input + "\\" + list[i])) {
			//prints stuff to track
			print("");
			print("-----------------------------------");
			print("");
			print("STARTING FOLDER", list[i]);
			processFolder(input + "\\" + list[i]);
			print("");
			print("COMPLETED FOLDER", list[i]);
		}
	}
}

function processFile(input, file) {
	//getFileList appends / to all subfolders. We don't want that. 
	if (endsWith(input, "/")) {
		index = lengthOf(input)-1;
		input = substring(input,0,index);
	}
	
	//prints stuff to track
	print("");
	print("PROCESSING IMAGE: " + input + File.separator + file);
	open(input+"\\"+file);
	
	//Removes any scaling
	run("Set Scale...", "distance=0 known=0 unit=pixel global");

	//find width of feature in image
	fft_values = getFFTValues(file);
	
	peakless_fft_values = getPeaklessFFTValues(fft_values); //removes peak
	
	half_max = getHM(peakless_fft_values);
	
	half_width = getHW(half_max, peakless_fft_values);

	px_width = getPxWidth(half_width, half_max, file);

	categorize(px_width); //saves image with edited file name

	
	//CLEAN UP
	close("*");
	run("Clear Results");
	
	print("RENAMING IMAGE TO INCLUDE WIDTH");
}

/*///////////////////////////////////////////////////////////////////////
FUNCTIONS
///////////////////////////////////////////////////////////////////////*/

function avg(array){
	sum = 0;
	array_length = array.length;
	for (i = 0; i<array_length; i++) {
		sum += array[i];
	}
	average = sum/array_length;
	return average;
}

function getFFTValues(file) {
	run("FFT");
	
	width = getWidth();
	makeRectangle(0,0,width/2,width);

	fft_values = getProfile(); //returns array of FFT(x) values

	fft_values = shift(fft_values); //shift down linearly by min{FFT(x)} to facilitate HW

	return fft_values;
}

function shift(array) {
	min = array[0];

	//find min{FFT(x)}
	for (i=1; i<=array.length-1; i++) {
		if (array[i] < min) {
			min = array[i];
		}
	}

	//shift FFT(x) down by min
	for (i = 0; i<=array.length-1; i++) {
		array[i]-=min;
	}

	return array;
}

function getPeaklessFFTValues(fft_values) {
/* Function takes in an array of FFT values and returns the set of 8 values preceding the spike */
	array_length = fft_values.length; 
	peakless_fft_values = Array.slice(fft_values,0,array_length-8);
	return peakless_fft_values;
}

function getHM(peakless_fft_values) {
	max_value = 0;
	array_length = peakless_fft_values.length;
	//average max in last 8 pixels\
	new_max_batch = Array.slice(peakless_fft_values, array_length-8, array_length);
	max_value = avg(new_max_batch);
	half_max = max_value/2;
	return half_max;
}

function getHW(half_max, peakless_fft_values) {
/* Function takes in half-max value and fft values and returns index of fft value closest to the half-max */
	
	//compare to first fft value to have a starting point.
	delta_HM = abs(half_max-peakless_fft_values[0]);

	//keeps track of best matches. Updated in loop below
	half_width = 0;

	//loops through all fft values and finds difference to half-max
	for (i = 1; i < peakless_fft_values.length-1; i++) {
		delta = abs(half_max-peakless_fft_values[i]);
		if (delta < delta_HM){ 
			delta_HM = delta;
			half_width = i;
		}
	}

	return half_width;
}

function getPxWidth(half_width,half_max,file) {
/* Function takes in half_width, half_max and file name inputs. Takes 4 points in the image's FFT image at half-max away from the center. Returns average of R-value corresponding to those 4 points. */
	selectWindow("FFT of " + file);
	FFT_width = getWidth();
	center = FFT_width/2;
	r1 = center-half_width; //center of FFT image is 0, edges are width/2 in pixels measured from corner
	r2 = center+half_width;

	//makes selections and measures R value
	makeSelection("point",newArray(r1,center,r2,center),newArray(center,r1,center,r2));
	run("Measure");

	
	selections = newArray(getResult("R",0),getResult("R",1),getResult("R",2),getResult("R",3));
	avg_px = avg(selections);

	avg_px_str = "" + avg_px; //needed to be string to return
	return avg_px;
}


function categorize(px_width) {
	px_width_std = d2s(px_width, 4);
	selectWindow(file);
	path1 = input + "\\" + file;
	path2 = input + "\\" + px_width_std + "_" + file;
	File.rename(path1, path2);
}

