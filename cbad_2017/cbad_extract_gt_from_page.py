
import numpy as np
import cv2
import os
from glob import glob
from tqdm import tqdm
from xml.etree import ElementTree as ET
import shutil

_ns = {'p': 'http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15'}
dataset_folder='TestBaselineCompetitionSimpleDocuments/'
output_folder='gt_cbad_2017_simple_test/'
os.makedirs(output_folder)
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

def get_baseline_points(xml_root,img):
    all_baseline_points=[]
    page_elements = xml_root.find('p:Page', _ns)
    text_regions= page_elements.findall('p:TextRegion', _ns)
    
    for text_region in text_regions:
        text_lines= text_region.findall('p:TextLine', _ns)
        for text_line in text_lines:    
            baseline=text_line.find('p:Baseline', _ns)
            baseline_points = baseline.attrib['points']
            all_baseline_points.append((baseline_points))
    return all_baseline_points


def xml_to_coordinates(t):
    result = []
    for p in t.split(' '):
        values = p.split(',')
        assert len(values) == 2
        x, y = int(float(values[0])), int(float(values[1]))
        result.append((x,y))
    result=np.array(result)
    return result

    
def extract_one_page(image_filename, output_dir, resize_size):
    img = cv2.imread(image_filename)
    page_filename = get_page_filename(image_filename)
    xml_root = ET.parse(page_filename)
    all_baseline_points=get_baseline_points(xml_root,img)
    save_name=os.path.join(output_dir,'baseline_gt_txts', '{}.jpg.txt'.format(get_image_basename(image_filename)))
    baseline_file=open(save_name,'w')
    for baseline_points in all_baseline_points:
        modified_baseline_points=baseline_points.replace(' ',';')
        baseline_file.write(modified_baseline_points)
        baseline_file.write('\n')
    baseline_file.close()
    
    save_and_resize(img, os.path.join(output_dir, 'images', '{}.jpg'.format(get_image_basename(image_filename))),
                    size=resize_ratio)

    shutil.copy(page_filename, os.path.join(output_dir, 'gt', '{}.xml'.format(get_image_basename(image_filename))))


def cbad_gt_generator(input_dir: str, output_dir: str, resize_ratio: int):

    image_filenames_list = glob('{}/**/*.jpg'.format(input_dir))

    os.makedirs(os.path.join('{}'.format(output_dir), 'images'))
    os.makedirs(os.path.join('{}'.format(output_dir), 'gt'))
    os.makedirs(os.path.join('{}'.format(output_dir), 'baseline_gt_txts'))
    for image_filename in tqdm(image_filenames_list):
        extract_one_page(image_filename, output_dir, resize_ratio)


cbad_gt_generator(dataset_folder,output_folder,None)    
        
        
        
