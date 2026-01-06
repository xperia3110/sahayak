import os
import numpy as np
import tensorflow as tf
from PIL import Image, ImageDraw
import json
from django.conf import settings

# Load model once at startup
MODEL_PATH = os.path.join(settings.BASE_DIR, 'ml_models', 'character_recognition_model.h5')
try:
    model = tf.keras.models.load_model(MODEL_PATH)
    print(f"Model loaded from {MODEL_PATH}")
except Exception as e:
    print(f"Error loading model: {e}")
    model = None

def points_to_image(points, size=(28, 28)):
    """
    Convert a list of points to a grayscale image.
    Points format: [{'x': 10, 'y': 20, 't': 123}, ...]
    """
    # Create a white background image
    # Using a larger canvas first to draw high res, then resize
    canvas_size = (500, 500) 
    img = Image.new('L', canvas_size, color=0) # Black background (MNIST style usually white on black or vice versa)
    draw = ImageDraw.Draw(img)
    
    # Find bounds to normalize/center if needed, but for now assuming drawing is somewhat centered
    # or we just draw raw coordinates if they are normalized.
    # The frontend sends raw local coordinates. We might need to normalize them.
    
    if not points:
        return np.zeros((1, 28, 28, 1))

    # Simple drawing
    # We need to handle 'null' breaks in points (strokes)
    # The frontend sends a list of dicts. It doesn't seem to send nulls in the JSON, 
    # but the frontend code adds null to _points list. 
    # The _recordedPoints in frontend does NOT contain nulls, it just contains points.
    # This is a limitation of the current frontend implementation (it loses stroke breaks).
    # For a simple MVP, we'll just connect all points or draw dots.
    # Let's assume we just draw lines between consecutive points.
    
    # To make it robust, we should probably fix frontend to send strokes.
    # But for now, let's just draw.
    
    for i in range(len(points) - 1):
        p1 = points[i]
        p2 = points[i+1]
        
        # Skip if time difference is too large (maybe a new stroke?) 
        # or if we had stroke separation data.
        
        x1, y1 = p1['x'], p1['y']
        x2, y2 = p2['x'], p2['y']
        
        draw.line([x1, y1, x2, y2], fill=255, width=15)

    # Resize to model input size
    img = img.resize(size)
    
    # Convert to numpy array and normalize
    img_array = np.array(img) / 255.0
    img_array = img_array.reshape(1, 28, 28, 1) # Batch dimension
    
    return img_array

def analyze_drawing(drawing_data):
    """
    Analyze the drawing data using the loaded model.
    Returns a dictionary of risk scores.
    """
    if model is None:
        return {"error": "Model not loaded"}
        
    points = drawing_data.get('points', [])
    img_input = points_to_image(points)
    
    try:
        prediction = model.predict(img_input)
        # Assuming model output is a probability distribution or a score
        # For this mock/MVP, let's assume it returns a class probability
        # We'll map it to a risk score.
        
        # Mocking the interpretation since we don't know the exact model output classes
        risk_score = float(np.max(prediction)) 
        
        return {
            "dysgraphia_risk": 1.0 - risk_score, # Just a dummy logic
            "dyslexia_risk": 0.1, # Placeholder
            "dyscalculia_risk": 0.1 # Placeholder
        }
    except Exception as e:
        print(f"Inference error: {e}")
        return {"error": str(e)}
