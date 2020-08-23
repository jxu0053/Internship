run("FFT");
makeRectangle(0, 0, 1024, 2048);
run("Plot Profile");
Plot.getValues(x,y);

/*for (i=0; i<x.length; i++)
	print(x[i],y[i]);*/

//print(x.length);

//Array.print(y) 

//SHIFT y DOWN
min = y[0]

for (i=1; i<=y.length-1; i++){
	if (y[i] < y[0]){
		min = y[i];
	}
}

for (i = 0; i<=y.length-1; i++){
	y[i]-=min;
}

Plot.create("Shifted FFT", "Distance (pixels)", "Shifted Gray Value", x, y);

//FINDING SPIKE LOCATION
prev_avg = 0;
max_delta_avg = 0;

spike_batch = 0;

//Loop over x-axis in batches of 4
for (i=0; i<=x.length-4; i=i+4){
	print(x[i], y[i]);
	//print(i);
	batch = Array.slice(y,i,i+4);
	Array.print("Current batch", batch);

	batch_avg = (y[i]+y[i+1]+y[i+2]+y[i+3])/4;
	print("Batch avg", batch_avg);

	//find batch largest difference between batch averages (when spike happens)
	if (i == 0){
		prev_avg = batch_avg;
	}
	delta_avg = batch_avg - prev_avg;
	print("Delta avg", delta_avg);
	if (delta_avg > max_delta_avg){
		max_delta_avg = delta_avg;
		spike_batch = i;
	}
	
	prev_avg = batch_avg;
}
print("Spike at batch #",spike_batch)

//FINDING MAX
//I am taking the max as the average of the max batch in case our 4 step cuts the into the spike.
max_batch = Array.slice(y,spike_batch-4, spike_batch);
max_value = (max_batch[0]+max_batch[1]+max_batch[2]+max_batch[3])/4;


//HWHM
print("Finding HW");

HM = max_value/2;
delta_HM = abs(HM-y[0]);

HW = 0;

for (i = 1; i < x.length-1; i++){
	print("Iteration #", i);
	delta = abs(HM-y[i]);
	print("Delta HM", delta);
	if (delta < delta_HM){
		delta_HM = delta;
		HW = i;
	}
}
print("max_value", max_value);
print("HWHM", HM, HW);


