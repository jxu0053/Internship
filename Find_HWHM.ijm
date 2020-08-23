img_title = getTitle();

run("FFT");
makeRectangle(0, 0, 1025, 2048);
run("Plot Profile");
Plot.getValues(x,y);


//SHIFT y DOWN
min = y[0]

for (i=1; i<=x.length-1; i++){
	if (y[i] < min){
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

//Loop over x-axis in batches of 8
for (i=0; i<=x.length-8; i=i+8){
	print(x[i], y[i]);
	//print(i);
	batch = Array.slice(y,i,i+8);
	Array.print("Current batch", batch);

	batch_avg = 0;
	for (j = 0; j < 8; j++){
		batch_avg += (y[i+j]);
	}
	batch_avg = batch_avg / 8;
	print("Batch avg", batch_avg);

	//find batch largest difference between batch averages (when spike happens)
	if (i == 0){
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
print("Spike at batch #",spike_batch)

//FINDING MAX
//I am taking the max as the average of the max batch in case our 4 step cuts the into the spike.
max_batch = Array.slice(y,spike_batch-8, spike_batch);
max_value = 0;
for (i = 0; i< 8; i++){
	max_value += max_batch[i];
}
max_value = max_value/8;


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

//FINDING PIXEL SIZE
r1 = 1024-HW; //center of FFT image is 0, edges are 1024
r2 = 1024+HW;
d = 2*HW; 

selectWindow("FFT of " + img_title);
makeSelection("point",newArray(r1,1024,r2,1024),newArray(1024,r1,1024,r2))

run("Measure");

avg_px = 0;
for (i=0; i<4; i++){
	avg_px += getResult("R", i);
}
avg_px = avg_px/4
avg_px_str = "" + avg_px;
return avg_px_str;

