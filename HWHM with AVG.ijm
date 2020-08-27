/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.


print("Is Data a DIRECTORY?", File.isDirectory(input));
processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	print("FILE LIST :");
	Array.print(list);
	//setBatchMode(true)
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix)) {
			//print("IMAGE: ", list[i]);
			processFile(input, output, list[i]);
		}
		else if(File.isDirectory(input + "\\" + list[i])) {
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

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	//print("FOLDERNAME", input);
	if (endsWith(input, "/")) {
		index = lengthOf(input)-1;
		input = substring(input,0,index);
	}
	print("");
	print("PROCESSING IMAGE: " + input + File.separator + file);
	open(input+"\\"+file);
	run("Set Scale...", "distance=0 known=0 unit=pixel global");

	fft_values = getFFTValues(file);
	
	new_max_batch = getNewMaxBatch(fft_values);
	
	half_max = getHM(new_max_batch);
	
	half_width = getHW(half_max, fft_values);

	px_width = getPxWidth(half_width, half_max, file);

	quality = getQuality(px_width);

	path = categorize(quality, px_width);

	close("*");
	run("Clear Results");
	
	print("SAVING TO: " + path);
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
	//run("Plot Profile");
	fft_values = getProfile();
	//close("Plot*");
	//Array.print(fft_values);
	fft_values = shift(fft_values);
	//Array.print(fft_values);

	return fft_values;
}

function shift(array) {
	min = array[0];
	for (i=1; i<=array.length-1; i++) {
		if (array[i] < min) {
			min = array[i];
		}
	}

	for (i = 0; i<=array.length-1; i++) {
		array[i]-=min;
	}

	return array;
}

function getNewMaxBatch(fft_values) {
	prev_avg = 0;
	max_delta_avg = 0;
	spike_index= 0;

	//Loop over gray-values in batches of 8
	for (i=0; i<=fft_values.length-8; i=i+8) {
		//print(x[i], y[i]);
		//print(i);
		batch = Array.slice(fft_values,i,i+8);
		//Array.print("Current batch", batch);
		
		batch_avg = avg(batch);

	//	print("Batch avg", batch_avg);
	
		//find batch largest difference between batch averages (when spike happens)
		if (i == 0) {
			prev_avg = batch_avg;
		}
		delta_avg = abs(batch_avg - prev_avg);
		//print("Delta avg", delta_avg);
		if (delta_avg > max_delta_avg){
			max_delta_avg = delta_avg;
			spike_index = i;
		}
		
		prev_avg = batch_avg;
	}
//	print("Spike at batch #",spike_index);
	new_max_batch= Array.slice(fft_values, spike_index-8, spike_index);
	return new_max_batch;

}

function getHM(new_max_batch) {
	max_value = avg(new_max_batch);

	//print("max_value", max_value);
	//HWHM
	//print("Finding HW");
	
	half_max = max_value/2;
	
	return half_max;
}

function getHW(half_max, fft_values) {
	delta_HM = abs(half_max-fft_values[0]);
	
	half_width = 0;
	
	for (i = 1; i < fft_values.length-1; i++) {
		//print("Iteration #", i);
		delta = abs(half_max-fft_values[i]);
		//print("Delta HM", delta);
		if (delta < delta_HM){ 
			delta_HM = delta;
			half_width = i;
		}
	}

	//print("HWHM", half_max, half_width);

	return half_width;
}

function getPxWidth(half_width,half_max,file) {
	//FINDING PIXEL SIZE
	selectWindow("FFT of " + file);
	FFT_width = getWidth();
	center = FFT_width/2;
	
	r1 = center-half_width; //center of FFT image is 0, edges are 1024
	r2 = center+half_width;
	d = 2*half_width; 
	
	makeSelection("point",newArray(r1,center,r2,center),newArray(center,r1,center,r2));
	
	run("Measure");
	
	selections = newArray(getResult("R",0),getResult("R",1),getResult("R",2),getResult("R",3));

	avg_px = avg(selections);

	avg_px_str = "" + avg_px;
	
	return avg_px_str;
}

function getQuality(px_width) {
	if (px_width < 3) {
		category = "trash";
	}
	else if (px_width >= 3 && px_width < 4){
		category = "low_qual";
	}
	else if (px_width >= 4 && px_width < 6) {
		category = "standard_qual";
	}
	else {
		category = "high_qual";
	}

	return category;
}

function categorize(quality, px_width) {
	path = output + "\\" + quality;

	if (!File.exists(path) || !File.isDirectory(path)) {
		File.makeDirectory(path);	
	}
	
	selectWindow(file);
	saveAs("tif", path + "\\" + px_width +file);

	return path;
}
