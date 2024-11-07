from ultralytics import YOLO
import cv2
from keras.applications.vgg16 import VGG16, preprocess_input
from keras.preprocessing.image import img_to_array
from keras.models import Model
from sklearn.metrics.pairwise import cosine_similarity
from numpy import dot
from numpy.linalg import norm
import numpy as np


def crop(image, model):
    results = model.predict(source=image, conf=0.85)  
    for result in results:
        boxes = result.boxes 
        for box in boxes:
            x1, y1, x2, y2 = box.xyxy[0]  
    cropped_image = image[int(y1):int(y2), int(x1):int(x2)] 
    return cropped_image

def embed(image,model):
    image = cv2.resize(image, (224, 224))  # Resize image to 224x224
    image = img_to_array(image)
    image = np.expand_dims(image, axis=0)
    image = preprocess_input(image)
    embedding = model.predict(image).flatten()
    return embedding

def cos_sim(embed1, embed2):
    cosine_similarity = dot(embed1, embed2) / (norm(embed1) * norm(embed2))
    return cosine_similarity

def main():
    model = YOLO('./weights/v5_30.pt')
    base_model = VGG16(weights='imagenet')
    embed_model = Model(inputs=base_model.input, outputs=base_model.layers[-2].output)

    image_path1 = './test/IMG_3969.JPG'  
    image_path2 = './test/IMG_3968.JPG' 
    image1 = cv2.imread(image_path1)
    image2 = cv2.imread(image_path2)
    cos_similarity = cos_sim(embed(crop(image1,model),embed_model), embed(crop(image2,model),embed_model))
    #return(cos_similarity)
    if cos_similarity >=0.5:
        AWB = ''
        with open('/Users/kamyeunglee/Downloads/socket 2/AWB.txt', 'r') as file: 
            lines = file.readlines()
            for line in lines:
                AWB = line
        return AWB
    
if __name__ == "__main__":
    main()
    


