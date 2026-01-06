# SAHAYAK - AI-Powered Early Screening for Learning Disabilities

![SAHAYAK Banner](https://i.imgur.com/your-banner-image-url.png) **SAHAYAK** is a web-based platform designed to provide an accessible, engaging, and data-driven screening tool for the early identification of risks associated with common learning disabilities like dyslexia, dysgraphia, and dyscalculia in young children.

---
## 📝 Table of Contents

- [Problem Statement](#-problem-statement)
- [Our Solution](#-our-solution)
- [Key Features](#-key-features)
  - [The Screening Games](#-the-screening-games)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Setup and Installation](#-setup-and-installation)
  - [Backend (Django)](#backend--django)
  - [Frontend (Flutter)](#frontend--flutter)
- [Team Members](#-team-members)

---
## 🎯 Problem Statement

Traditional methods for diagnosing learning disabilities are often:
- **Delayed:** Diagnosis typically occurs after a child has already faced significant academic and emotional challenges.
- **Inaccessible:** Expert assessments can be costly and geographically limited, creating a barrier for many families.
- **Not Child-Friendly:** Clinical tests can be intimidating and stressful for young children, potentially affecting their performance.
- **Siloed:** Tools usually focus on a single disability, requiring multiple, separate assessments.

---
## ✨ Our Solution

SAHAYAK addresses these challenges by transforming the screening process into a series of fun, interactive games. Our platform uses a **two-stage AI engine** to analyze not just the outcome of the child's actions, but the *process* of their play—capturing subtle cognitive and motor-skill markers to build a holistic risk profile.

This approach provides a non-invasive, scalable, and engaging first step, empowering parents and educators to seek professional intervention earlier than ever before.

---
## 🚀 Key Features

* **Holistic Screening:** A single platform to screen for risks of Dyslexia, Dysgraphia, and Dyscalculia.
* **Engaging Gamified Experience:** A child-friendly interface with three distinct games designed to be fun and intuitive.
* **Parent/Educator Dashboard:** A secure portal for parents to manage child profiles and view clear, easy-to-understand screening reports.
* **AI-Powered Analysis:** A robust backend that analyzes gameplay data to generate an objective risk assessment.

### 🎮 The Screening Games

1.  **Echo Explorers (Dyslexia Screening):**
    * A sound-based adventure where the child explores a magical forest and matches auditory prompts to pictures. This game tests **phonological awareness** and **auditory processing speed** without requiring any reading.

2.  **Star Tracer (Dysgraphia Screening):**
    * A cosmic journey where the child traces the letters and symbols. This game analyzes the child's **fine motor control, motor planning, and spatial awareness** by capturing the entire stroke kinematics of their drawings.

3.  **Monster Munch (Dyscalculia Screening):**
    * A playful feeding game where the child gives a cute monster the correct number of snacks. This game tests core **number sense, subitizing (instant quantity recognition), and magnitude comparison** skills.

---
## 🛠️ Technology Stack

### Frontend
| Technology | Description |
| :--- | :--- |
| **Flutter** | A cross-platform UI toolkit for building beautiful, natively compiled applications for web, mobile, and desktop from a single codebase. |
| **Dart** | The programming language used by Flutter. |
| **Rive** | For creating interactive and complex character animations (like the monster in "Monster Munch"). |
| **Go Router** | For declarative, URL-based navigation in the web application. |

### Backend
| Technology | Description |
| :--- | :--- |
| **Django** | A high-level Python web framework that enables rapid development of secure and maintainable applications. |
| **Django Rest Framework** | A powerful toolkit for building Web APIs, serving as the bridge to our Flutter frontend. |
| **Python** | The core programming language for our backend and AI models. |

### AI & Data Science
| Technology | Description |
| :--- | :--- |
| **TensorFlow & Keras** | For building and training our deep learning models, specifically the CNN for handwriting analysis. |
| **Scikit-learn** | For our classical machine learning models (like the final ensemble classifier) and data preprocessing. |
| **Jupyter Notebooks** | For data exploration, model prototyping, and experimentation. |
| **Pandas** | For data manipulation and analysis of our "blueprint" datasets. |

---
## 📂 Project Structure

```
sahayak/
├── backend/
│   ├── venv/
│   ├── sahayak_core/
│   ├── api/
│   ├── ml_models/
│   ├── notebooks/
│   └── manage.py
└── frontend/
    ├── lib/
    │   ├── models/
    │   ├── providers/
    │   ├── screens/
    │   ├── services/
    │   ├── assets/
    │   └── main.dart
    └── pubspec.yaml
```

---
## ⚙️ Setup and Installation

### Prerequisites
- **Git**
- **Python 3.8+**
- **Flutter SDK**

### 1. Backend (Django)

1.  **Navigate to the backend directory:**
    ```bash
    cd sahayak/backend
    ```

2.  **Create and activate a virtual environment:**
    ```bash
    python -m venv venv
    
    # On macOS/Linux:
    source venv/bin/activate
    
    # On Windows:
    .\venv\Scripts\Activate.ps1
    ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Run database migrations:**
    ```bash
    python manage.py makemigrations
    python manage.py migrate
    ```

5.  **Create a superuser (for Admin access):**
    ```bash
    python manage.py createsuperuser
    ```

6.  **Start the server:**
    ```bash
    python manage.py runserver
    ```
    The backend will run at `http://127.0.0.1:8000`.

### 2. Frontend (Flutter)

1.  **Navigate to the frontend directory:**
    ```bash
    cd sahayak/frontend
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    # For Web (Recommended for development)
    flutter run -d chrome

    # For Desktop/Mobile
    flutter run
    ```
    The frontend typically runs at `http://localhost:55663` (port may vary).

---
## 🧪 Testing and Verification

### Quick Integration Test
1.  Ensure Backend is running.
2.  Navigate to `sahayak/backend` and run:
    ```bash
    python test_api.py
    ```
    *(Note: This assumes `test_api.py` exists in the backend root based on project history)*

### Manual Frontend Test
1.  Open the Flutter app.
2.  Navigate to the Login/Register screen.
3.  Create a new user.
4.  Verify you are redirected to the Home Screen.

---
## 🔌 API Endpoints
Key endpoints available in the backend:

- **Auth**:
    - `POST /api/auth/register/`
    - `POST /api/auth/login/`
- **Children**:
    - `GET /api/children/` (List profiles)
    - `POST /api/children/` (Create profile)
- **Sessions**:
    - `GET /api/sessions/` (View history)
    - `POST /api/sessions/` (Save game data)

---
## 🔧 Troubleshooting
- **CORS Errors**: Ensure `django-cors-headers` is installed and `CORS_ALLOWED_ORIGINS` in `settings.py` includes your frontend URL.
- **Database Errors**: Run `python manage.py migrate` to ensure the schema is up to date.
- **Module Not Found**: Ensure you have activated the virtual environment (`source venv/bin/activate`) before running python commands.

---
## 🧑‍💻 Team Members

| Name | Registration No. |
| :--- | :--- |
| ASWINI T | STC22CS023 |
| COLLINS SHIBI KURIAN | STC22CS030 |
| KRISHNAJA UNNI | STC22CS042 |
| AKHIL U | GIT22CS004 |

**Project Supervisor:** Dr. Bibin Vincent
````