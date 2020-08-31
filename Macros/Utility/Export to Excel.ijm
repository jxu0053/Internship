/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "file") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tiff") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

action(input,output)

function action(input, output) {
	print(output);
	filename = File.getName(input);
	print("filename");
    open(input);
    
    run("FFT");
	width = getWidth();
	run("Select All");
    run("Clear Results");
    name = filename +".csv";
    profile = getProfile();
    new_profile = shift(profile);
    for (i=0; i<new_profile.length; i++) {
    	print(i, new_profile[i]);
    	setResult("Value", i, new_profile[i]);
    	updateResults();
    }
    saveAs("Results", output +"//"+ name);  
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
