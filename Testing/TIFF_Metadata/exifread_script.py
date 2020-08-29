import exifread
import os
from exif import Image
from exif import LightSource
import pyexiv2
import piexif

"""WITH PIEXIF""" #DOES NOT SUPPORT .TIFF
def piexifAdd():
    exif_dict = piexif.load("Images/Test_image.tiff")
    for ifd in ("0th", "Exif", "GPS", "1st"):
        for tag in exif_dict[ifd]:
            print(piexif.TAGS[ifd][tag]["name"], exif_dict[ifd][tag])

    exif_dict['ImageDescription'] = "3"
    exif_bytes = piexif.dump(exif_dict)
    new_Image = open("test2.tiff",'wb')
    piexif.insert(exif_bytes,"Images/Test_image.tiff")


"""WITH PYEXIV2 """#IDK WHY IT DOESNT WORK
"""def setTag():
    open_img = open('Images/Test_image.tiff', 'rb')
    img = Image(open_img)
    img.set('Exif.Image.ImageDescription',"3")
    #print(img.Exif.Image.ImageDescription)
    print(img.has_exif)
    #img.modify_exif({'Exif.Image.ImageDescription':"3"})
    #data = img.read_exif()
    #print (data)
    #img.close()
    return None

"""

# Open image file for reading (binary mode)
"""WITH EXIFREAD""" #CAN'T WRITE?
def batch(path):
    file_path = path

    for file in os.listdir(path):
        if file.endswith('.tiff'):
            file_path = path + "/" + file
            f = open(file_path, 'rb')

            # Return Exif tags
            tags = exifread.process_file(f)

            try:
                print(file + "Key: %s, value %s" % ('ImageDescription', tags['Image ImageDescription']))
            except KeyError:
                print("ERROR : Contains file that does not have ImageDescription tag.")
                break
def single(image_path):
    f = open(image_path, 'rb')

    # Return Exif tags
    tags = exifread.process_file(f)
    print(tags)
    for tag in tags.keys():
        if tag not in ('JPEGThumbnail', 'TIFFThumbnail', 'Filename', 'EXIF MakerNote'):
            print("Key: %s, value %s" % (tag, tags[tag]))
    return f

"""WITH EXIF""" #WORKS BUT REMOVES ALL EXIF FOUND BY PIEXIF AND EXIFREAD
def addTag(image_path):
    with open(image_path, 'rb') as image_file:
        my_image = Image(image_file)

    print(my_image.has_exif)

    my_image.make = "4"

    print(my_image.make)
    print(my_image.has_exif)

    with open('modified_image.tiff','wb') as new_image_file:
        new_image_file.write(my_image.get_file())

    with open('modified_image.tiff','rb') as new_image:
        my_new_image = Image(new_image)

    print(my_new_image.has_exif)

def hasExif1(image_path) :
    with open(image_path,'rb') as new_image:
        my_new_image = Image(new_image)

    print("Other lib", my_new_image.has_exif)
    print(my_new_image.make)

###################################TEST################################
image_path = "Images\Test_image.tiff"
"""path = "Images"
#batch(path)
single(image_path)
"""

#single(image_path)
#addTag(image_path)
#setTag()
"""
single('modified_image.tiff')
hasExif1('modified_image.tiff')
"""
####################################CODE################################
