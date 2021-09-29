
import numpy as np
import cv2
import os
from glob import glob
from tqdm import tqdm
from xml.etree import ElementTree as ET
import shutil

_ns = {'p': 'http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15'}
dataset_folder='TestBaselineCompetitionSimpleDocuments/'
output_folder='cropped_cbad_2017_simple_test/'
resize_ratio=None


def save_and_resize(img: np.array, filename: str, size=None):
    if size is not None:
        h, w = img.shape[:2]
        resized = cv2.resize(img, (int(w*size), int(h*size)),
                             interpolation=cv2.INTER_LINEAR)
        cv2.imwrite(filename, resized)
    else:
        cv2.imwrite(filename, img)


def get_page_filename(image_filename:str):
    return os.path.join(os.path.dirname(image_filename),
                        'page',
                        '{}.xml'.format(os.path.basename(image_filename)[:-4]))
                        
def get_image_basename(image_filename:str):
    return os.path.basename(image_filename)[:-4]                      

def get_text_region_images(xml_root,img):
    text_region_images=[]
    page_elements = xml_root.find('p:Page', _ns)
    regions= page_elements.findall('p:TextRegion', _ns)
    for region in regions:
        region_id = region.attrib['id']
        coords=region.find('p:Coords', _ns)
        points = coords.attrib['points']
        cnt=xml_to_coordinates(points)
        (x,y,w,h) = cv2.boundingRect(cnt)
        if x<=0:
            x=1
        crop_img = img[y:y+h, x:x+w]
        text_region_images.append((crop_img,region_id,x,y))
    return text_region_images


def xml_to_coordinates(t):
    result = []
    for p in t.split(' '):
        values = p.split(',')
        assert len(values) == 2
        x, y = int(float(values[0])), int(float(values[1]))
        result.append((x,y))
    result=np.array(result)
    return result

    
def crop_one_page(image_filename, output_dir, resize_size):
    img = cv2.imread(image_filename)
    page_filename = get_page_filename(image_filename)
    xml_root = ET.parse(page_filename)
    text_region_images=get_text_region_images(xml_root,img)

    for text_region_image in text_region_images:
        save_name=os.path.join(output_dir,'crop_text_regions',
                  '{}#{}#{}#{}.jpg'.format(text_region_image[1],text_region_image[2] ,text_region_image[3],get_image_basename(image_filename) ))
        save_and_resize(text_region_image[0],save_name,size=resize_ratio)
    
    save_and_resize(img, os.path.join(output_dir, 'images', '{}.jpg'.format(get_image_basename(image_filename))),
                    size=resize_ratio)

    shutil.copy(page_filename, os.path.join(output_dir, 'gt', '{}.xml'.format(get_image_basename(image_filename))))


def cbad_generator(input_dir: str, output_dir: str, resize_ratio: int):

    image_filenames_list = glob('{}/**/*.jpg'.format(input_dir))

    os.makedirs(os.path.join('{}'.format(output_dir), 'images'))
    os.makedirs(os.path.join('{}'.format(output_dir), 'gt'))
    os.makedirs(os.path.join('{}'.format(output_dir), 'crop_text_regions'))
    for image_filename in tqdm(image_filenames_list):
        crop_one_page(image_filename, output_dir, resize_ratio)


cbad_generator(dataset_folder,output_folder,None)    
        
        
        
