import os
# import libtiff
import subprocess
import exifread_script


def writeTag(image_path):
    print("Attempting to rewrite tag")
    f = open(image_path, 'rb')

    subprocess.call('tiffset -s 270 4')


image_path = "Images\Humerus_Partial_XradiaVersa510_5 from Cylinder4 Marked Slices04.tiff"

writeTag(image_path)
print("Now printing tags")
#exifread_script.single(image_path)