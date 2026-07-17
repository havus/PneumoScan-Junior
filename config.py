"""
=============================================================
config.py

Project:
Pediatric Pneumonia Detection using Xception CNN

Application:
PneumoScan Junior

Developer:
Harish

Description:
Global configuration file for the PneumoScan Junior application.

This file stores all constants used throughout the project.

=============================================================
"""

from pathlib import Path

# ==========================================================
# PROJECT ROOT
# ==========================================================

PROJECT_ROOT = Path(__file__).resolve().parent

# ==========================================================
# APPLICATION INFORMATION
# ==========================================================

APP_NAME = "PneumoScan Junior"

PROJECT_TITLE = (
    "Pediatric Pneumonia Detection using Xception CNN"
)

APP_SUBTITLE = (
    "Deep Learning Based Clinical Decision Support Prototype "
    "for Pediatric Chest X-ray Analysis"
)

APP_VERSION = "2.0"

DEVELOPER = "Harish"

ORGANIZATION = "Independent Research Project"

# ==========================================================
# STREAMLIT CONFIGURATION
# ==========================================================

PAGE_ICON = "🫁"

LAYOUT = "wide"

SIDEBAR_STATE = "expanded"

# ==========================================================
# PROJECT DIRECTORIES
# ==========================================================

MODEL_DIR = PROJECT_ROOT

SAMPLE_DIR = PROJECT_ROOT / "sample_images"

NORMAL_SAMPLE_DIR = SAMPLE_DIR / "normal"

PNEUMONIA_SAMPLE_DIR = SAMPLE_DIR / "pneumonia"

ASSETS_DIR = PROJECT_ROOT / "assets"

# ==========================================================
# MODEL
# ==========================================================

MODEL_NAME = "Xception CNN"

MODEL_FILENAME = "Xception_final_gradcam.keras"

MODEL_PATH = MODEL_DIR / MODEL_FILENAME

FRAMEWORK = "TensorFlow"

FRAMEWORK_VERSION = "2.20"

PREDICTION_THRESHOLD = 0.50

# ==========================================================
# IMAGE
# ==========================================================

IMAGE_WIDTH = 224

IMAGE_HEIGHT = 224

IMAGE_SIZE = (IMAGE_WIDTH, IMAGE_HEIGHT)

IMAGE_CHANNELS = 3

SUPPORTED_IMAGE_TYPES = [
    "jpg",
    "jpeg",
    "png"
]

# ==========================================================
# CLASSES
# ==========================================================

CLASS_NAMES = [
    "Normal",
    "Pneumonia"
]

NEGATIVE_CLASS = CLASS_NAMES[0]

POSITIVE_CLASS = CLASS_NAMES[1]

# ==========================================================
# DATASET
# ==========================================================

DATASET_NAME = (
    "Chest X-ray Pneumonia Dataset"
)

DATASET_DESCRIPTION = (
    "Pediatric Chest X-ray Dataset"
)

DATASET_SOURCE = (
    "Kaggle"
)

# ==========================================================
# USER INTERFACE
# ==========================================================

IMAGE_SOURCE_TITLE = "Image Source"

IMAGE_PREVIEW_TITLE = "Chest X-ray Preview"

PREDICTION_TITLE = "Prediction"

MODEL_INFORMATION_TITLE = "Model Summary"

PROBABILITY_TITLE = "Prediction Probability"

UPLOAD_LABEL = "Upload Pediatric Chest X-ray"

UPLOAD_HELP = (
    "Supported formats: JPG, JPEG and PNG."
)

SAMPLE_LABEL = "Choose a Sample Image"

CONFIDENCE_LABEL = "Confidence"

INFERENCE_TIME_LABEL = "Inference Time"

REFERENCE_DIAGNOSIS_LABEL = "Reference Diagnosis"

DATASET_LABEL = "Dataset"

# ==========================================================
# COLORS
# ==========================================================

PRIMARY_COLOR = "#0B5394"

SECONDARY_COLOR = "#1565C0"

SUCCESS_COLOR = "#2E8B57"

ERROR_COLOR = "#C0392B"

WARNING_COLOR = "#F39C12"

BACKGROUND_COLOR = "#FFFFFF"

CARD_BACKGROUND = "#F8F9FA"

SIDEBAR_BACKGROUND = "#F3F6FA"

BORDER_COLOR = "#DDDDDD"

TEXT_COLOR = "#333333"

SUBTEXT_COLOR = "#666666"

# ==========================================================
# DISCLAIMER
# ==========================================================

DISCLAIMER = (
    "Disclaimer: This application is intended for research and educational "
    "purposes only. The model predicts the probability of "
    "pneumonia from pediatric chest X-ray images and should "
    "not be used as a substitute for professional medical judgment."
)

# ==========================================================
# FOOTER
# ==========================================================

FOOTER = (
    f"{APP_NAME} | Version {APP_VERSION} | "
    "Research Prototype | "
    f"Developed by {DEVELOPER}"
)
