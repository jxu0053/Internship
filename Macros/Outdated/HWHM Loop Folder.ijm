/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix)) {
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	open(input+"\\"+file);
	run("Set Scale...", "distance=0 known=0 unit=pixel global");
	
	gray_val = obtainFFT(file);
	
	spike_location = findSpike(gray_val);
	
	half_max = HM(spike_location);
	
	half_width = HW(half_max, gray_val);

	px_width = pxWidth(half_width, half_max, file);

	quality = findQuality(px_width);

	path = categorize(quality, px_width);

	close("*");
	run("Clear Results");
	
	print("Saving to: " + path);
}

/*///////////////////////////////////////////////////////////////////////
FUNCTIONS
///////////////////////////////////////////////////////////////////////*/
function avg(array){
	sum = 0;
	length = array.length;
	for (i = 0; i<length, i++) {
		sum += array[i];
	}
	avg = sum/length;

	return avg;
}

function obtainFFT(file) {
	run("FFT");
	width = getWidth();
	makeRectangle(0,0,width/2,width);
	//run("Plot Profile");
	gray_val = getProfile();
	//close("Plot*");
	Array.print(gray_val);
	gray_val = shift(gray_val);
	Array.print(gray_val);

	return gray_val;
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

function findSpike(gray_val) {
	prev_avg = 0;
	max_delta_avg = 0;
	spike_batch = 0;

	//Loop over gray-values in batches of 8
	for (i=0; i<=gray_val.length-8; i=i+8) {
		//print(x[i], y[i]);
		//print(i);
		batch = Array.slice(gray_val,i,i+8);
		Array.print("Current batch", batch);
	
		batch_avg = 0;
		for (j = 0; j < 8; j++) {
			batch_avg += (gray_val[i+j]);
		}
		batch_avg = batch_avg / 8;
		print("Batch avg", batch_avg);
	
		//find batch largest difference between batch averages (when spike happens)
		if (i == 0) {
			prev_avg = batch_avg;
		}
		delta_avg = abs(batch_avg - prev_avg);
		print("Delta avg", delta_avg);
		if (delta_avg > max_delta_avg){
			max_delta_avg = delta_avg;
			spike_batch = i;
		}
		
		prev_avg = batch_avg;
	}
	print("Spike at batch #",spike_batch);
	max_batch = Array.slice(gray_val, spike_batch-8, spike_batch);
	return max_batch;

}

function HM(spike_location) {
	max_value = 0;
	for (i = 0; i< 8; i++) {
		max_value += spike_location[i];
	}
	max_value = max_value/8;
	print("max_value", max_value);
	//HWHM
	print("Finding HW");
	
	half_max = max_value/2;
	
	return half_max;
}

function HW(half_max, gray_val) {
	delta_HM = abs(half_max-gray_val[0]);
	
	half_width = 0;
	
	for (i = 1; i < gray_val.length-1; i++) {
		print("Iteration #", i);
		delta = abs(half_max-gray_val[i]);
		print("Delta HM", delta);
		if (delta < delta_HM){ 
			delta_HM = delta;
			half_width = i;
		}
	}

	print("HWHM", half_max, half_width);

	return half_width;
}

function pxWidth(half_width,half_max,file) {
	//FINDING PIXEL SIZE
	selectWindow("FFT of " + file);
	FFT_width = getWidth();
	center = FFT_width/2;
	
	r1 = center-half_width; //center of FFT image is 0, edges are 1024
	r2 = center/2+half_width;
	d = 2*half_width; 
	
	makeSelection("point",newArray(r1,center,r2,center),newArray(center,r1,center,r2));
	
	run("Measure");
	
	avg_px = 0;
	for (i=0; i<4; i++) {
		avg_px += getResult("R", i);
	}
	avg_px = avg_px/4;
	avg_px_str = "" + avg_px;
	
	return avg_px_str;
}

function findQuality(px_width) {
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
