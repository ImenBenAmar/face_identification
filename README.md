
# Desktop Facial Recognition Application

This application is a desktop facial recognition system that utilizes a Flask API for handling facial recognition tasks. The system can add new individuals to the database, upload their images, and update the facial recognition model. It also recognizes individuals and retrieves their details from the database.

## Table of Contents

- [Features](#features)
- [Technologies Used](#technologies-used)
- [Setup and Installation](#setup-and-installation)
- [API Endpoints](#api-endpoints)
- [Usage](#usage)
- [Database Schema](#database-schema)
- [Contributing](#contributing)

## Features
- Add new individuals to the database
- Upload images for new individuals
- Update the facial recognition model with new images
- Recognize individuals from images
- Retrieve recognized individuals' details from the database

## Technologies Used

- **Python**: Core language
- **Flask**: Web framework for the API
- **OpenCV**: Image processing
- **dlib**: Facial recognition
- **scikit-learn**: Machine learning (SVM classifier)
- **pyodbc**: Database connectivity
- **SQL Server**: Database management
- **pickle**: Model and data serialization

## Setup and installation
### Prerequisites

- Python 3.x
- SQL Server
- Required Python libraries (listed in `requirements.txt`)

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/ImenBenAmar/face_identification.git
   cd facial-recognition-app

2. **Create and activate a virtual environment:** 
  ```sh
  python -m venv venv
  source venv/bin/activate 
 ```
3. **Install the required libraries:** 
```sh
pip install -r requirements.txt
```
4. **Download dlib models and place them in the face_model directory:**
- shape_predictor_68_face_landmarks.dat
- dlib_face_recognition_resnet_model_v1.dat
5. **Set up SQL Server:**
- Create a database.
- Ensure the connection string in the code matches your SQL Server setup.
## Running the Application
1. **Start the Flask API:**
```sh
python API.py
```



## API Endpoint

### Create Folder
Creates a new folder for a person and adds their details to the database.
```http
POST /create_folder
```
- Request Body:
```http
{
  "name": "John",
  "surname": "Doe",
  "phone_number": "1234567890",
  "cin": "ABC123"
}
```
- Response:
```http
{
  "message": "Person added successfully and folder created successfully.",
  "id": 1,
  "path_folder": "./face_model/data/1"
}
```
### Upload Images
Uploads images to the person's folder.
```http
POST /upload_images
```
- Request Form:

     - images: List of image files
     - id: Person ID

- Response
```http
{
  "message": "Images uploaded successfully to ./face_model/data/1."
}
```
### Update_model
Updates the facial recognition model with new images.
```http
POST /update_model
```
- Request Body:
```http
{
  "id": 1
}
```
- Response:
```http
{
  "message": "Model updated successfully."
}
```
### recognize
Recognizes a person from an image.
```http
POST / recognize
```
- Request Body:
   - Image file
- Response:
```http
{
  "id": "1",
  "confidence": 0.95,
  "name": "John",
  "surname": "Doe",
  "cin": "ABC123",
  "phone_number": "1234567890"
}
```



## Usage
1. **Add a new person:**
Use the /create_folder endpoint to add a new person's details and create a folder for their images.
2. **Upload images:**
Use the /upload_images endpoint to upload images of the new person.
3. **Update the model:**
Use the /update_model endpoint to update the facial recognition model with the new images.
4. **Recognize a person:**
Use the /recognize endpoint to recognize a person from an image and retrieve their details from the database.












### Database Schema

The database contains a single table named `Persons` with the following columns:

| Column          | Type    | Description                         |
| :-------------- | :------ | :---------------------------------- |
| `id`            | `INT`   | **Primary Key**. Unique identifier for each person |
| `nom`           | `VARCHAR` | First name of the person |
| `prenom`        | `VARCHAR` | Surname of the person |
| `numero_telephone` | `VARCHAR` | Phone number of the person |
| `cin`           | `VARCHAR` | National identification number of the person |
| `folder_path`   | `VARCHAR` | Path to the folder containing the person's images |

## Contributing
Contributions are welcome! Please open an issue or submit a pull request with your changes. 