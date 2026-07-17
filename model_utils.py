"""
==========================================================
model_utils.py

Project:
PneumoScan Junior

Description:
Utilities for loading the trained Xception model,
downloading it automatically from GitHub Releases,
and performing model inference.

Author:
Harish Muhammad
==========================================================
"""

# ==========================================================
# IMPORTS
# ==========================================================

from __future__ import annotations

from pathlib import Path

import streamlit as st

from config import (
    MODEL_DIR,
    MODEL_NAME,
    MODEL_PATH,
)

import requests
import shutil
import time

# ==========================================================
# GITHUB RELEASE
# ==========================================================

MODEL_URL = (
    "https://github.com/harishmuh/"
    "PneumoScan-Junior/releases/download/"
    "v1.0.0/Xception_final_gradcam.keras"
)

# ==========================================================
# MODEL DOWNLOAD
# ==========================================================

def download_model() -> None:
    """
    Download the trained model from GitHub Releases.

    The model is downloaded only once and cached locally.
    Automatic retry is performed if the download is interrupted.
    """

    MODEL_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    if MODEL_PATH.exists():
        return

    temp_path = MODEL_PATH.with_suffix(".download")

    with st.spinner(

        "🚀 Preparing PneumoScan Junior\n\n"

        "The trained AI model is being downloaded.\n\n"

        "⏳ First launch only.\n"

        "Please wait about 2–5 minutes depending on your internet connection.\n\n"

        "Future launches will start much faster."

    ):

        retries = 3

        for attempt in range(retries):

            try:

                response = requests.get(

                    MODEL_URL,

                    stream=True,

                    timeout=(30, 300),

                    allow_redirects=True,

                )

                response.raise_for_status()

                total_size = int(
                    response.headers.get(
                        "content-length",
                        0,
                    )
                )

                downloaded = 0

                progress_bar = st.progress(0)

                status = st.empty()

                with open(temp_path, "wb") as f:

                    for chunk in response.iter_content(
                        chunk_size=1024 * 1024,
                    ):

                        if not chunk:
                            continue

                        f.write(chunk)

                        downloaded += len(chunk)

                        if total_size > 0:

                            fraction = downloaded / total_size

                            progress_bar.progress(
                                min(fraction, 1.0)
                            )

                            status.write(

                                f"Downloaded "
                                f"{downloaded / (1024**2):.1f} MB "
                                f"of "
                                f"{total_size / (1024**2):.1f} MB"

                            )

                shutil.move(
                    temp_path,
                    MODEL_PATH,
                )

                progress_bar.empty()

                status.empty()

                st.success(
                    "✅ AI model downloaded successfully."
                )

                return

            except Exception as e:

                if temp_path.exists():
                    temp_path.unlink()

                if attempt < retries - 1:

                    st.warning(

                        f"Download interrupted. "

                        f"Retrying ({attempt+2}/{retries})..."

                    )

                    time.sleep(3)

                else:

                    raise RuntimeError(

                        "Unable to download the trained model "

                        "from GitHub Releases.\n\n"

                        f"Details: {e}"

                    )

# ==========================================================
# MODEL CHECK
# ==========================================================

def ensure_model_exists() -> None:
    """
    Ensure that the trained model exists.

    If the model is missing,
    it will be downloaded automatically.
    """

    if MODEL_PATH.exists():

        return

    download_model()

# ==========================================================
# MODEL INFORMATION
# ==========================================================

def get_model_path() -> Path:
    """
    Return the local model path.
    """

    ensure_model_exists()

    return MODEL_PATH

# ==========================================================
# TENSORFLOW IMPORT
# ==========================================================

from keras.models import load_model as keras_load_model

# ==========================================================
# MODEL LOADER
# ==========================================================

@st.cache_resource(
    show_spinner=False
)
def load_model():
    """
    Load the trained Xception model.

    The model is downloaded automatically from
    GitHub Releases if it does not already exist.

    Returns
    -------
    keras.Model
        Loaded TensorFlow/Keras model.
    """

    model_path = get_model_path()

    model = keras_load_model(

        model_path,

        compile=False,

    )

    return model


# ==========================================================
# MODEL SUMMARY
# ==========================================================

def get_model():
    """
    Return the cached model.

    This function simply wraps load_model()
    and improves code readability in other modules.
    """

    return load_model()


# ==========================================================
# MODEL READY CHECK
# ==========================================================

def is_model_available() -> bool:
    """
    Check whether the trained model is available.

    Returns
    -------
    bool
    """

    return MODEL_PATH.exists()

# ==========================================================
# PREDICTION
# ==========================================================

def predict(image):
    """
    Predict pediatric pneumonia from a preprocessed image.

    Parameters
    ----------
    image : np.ndarray

    Returns
    -------
    dict
    """

    model = load_model()

    probability = float(

        model.predict(

            image,

            verbose=0,

        )[0][0]

    )

    probability = max(

        0.0,

        min(

            1.0,

            probability,

        ),

    )

    normal_probability = 1.0 - probability

    pneumonia_probability = probability

    if probability >= 0.5:

        predicted_class = "Pneumonia"

        confidence = probability

    else:

        predicted_class = "Normal"

        confidence = normal_probability

    return {

        "predicted_class": predicted_class,

        "confidence": confidence,

        "normal_probability": normal_probability,

        "pneumonia_probability": pneumonia_probability,

    }


# ==========================================================
# PUBLIC API
# ==========================================================

__all__ = [

    "load_model",

    "predict",

]