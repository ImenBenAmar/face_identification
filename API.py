import os
import cv2
import numpy as np
import pickle
from flask import Flask, request, jsonify
from flask_cors import CORS
import dlib
from sklearn.svm import SVC
from sklearn.preprocessing import LabelEncoder
import pyodbc

def get_db_connection():
    connection_string = (
        r'DRIVER={ODBC Driver 17 for SQL Server};'
        r'SERVER=DESKTOP-L0BASO8;'  # Replace with your server name and instance
        r'DATABASE=patient;'  # Replace with your database name
        r'Trusted_Connection=yes;'  # Use Windows authentication
    )

    try:
        conn = pyodbc.connect(connection_string)
        print("Connection successful")
        return conn
    except pyodbc.Error as e:
        print("Error connecting to database: ", e)
        return None

def save_person_to_db(person_id, name, surname, phone_number, cin, folder_path):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO Persons (id, nom, prenom , numero_telephone , cin, folder_path) VALUES (?, ?, ?, ?, ?, ?)",
                       (person_id, name, surname, phone_number, cin, folder_path))
        conn.commit()
        cursor.close()
        conn.close()
        print(f"Successfully saved {name} with ID {person_id} to the database.")
    except Exception as e:
        print(f"Error saving to database: {e}")
        
# Path to save images
save_directory = "./face_model/data"

# Initialize dlib models
pose_predictor_68_point = dlib.shape_predictor('./face_model/shape_predictor_68_face_landmarks.dat')
face_encoder = dlib.face_recognition_model_v1('./face_model/dlib_face_recognition_resnet_model_v1.dat')
face_detector = dlib.get_frontal_face_detector()

# Load embeddings and labels
embeddings_file = './face_model/embeddings.pkl'
if os.path.exists(embeddings_file):
    with open(embeddings_file, 'rb') as f:
        embeddings, labels = pickle.load(f)
else:
    embeddings = np.empty((0, 128))
    labels = []

# Load SVM classifier
classifier_file = './face_model/classifier.pkl'
if os.path.exists(classifier_file):
    with open(classifier_file, 'rb') as f:
        clf, le = pickle.load(f)
else:
    clf = SVC(kernel='linear', probability=True)
    le = LabelEncoder()

def extract_face_embeddings(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = face_detector(gray, 1)
    if len(faces) == 0:
        return None
    else:
        face = faces[0]
        shape = pose_predictor_68_point(image, face)
        face_descriptor = face_encoder.compute_face_descriptor(image, shape)
        return np.array(face_descriptor)


app = Flask(__name__)
CORS(app)

@app.route('/create_folder', methods=['POST'])
def create_folder():
    data = request.json
    name = data.get('name')
    surname = data.get('surname')
    phone_number = data.get('phone_number')
    cin = data.get('cin')

    if not name or not surname or not phone_number or not cin:
        return jsonify({"error": "All fields are required"}), 400

    # Convert labels to a list if it's a NumPy array
    labels_list = labels.tolist() if isinstance(labels, np.ndarray) else labels
    
    # Generate a unique person_id by incrementing the max existing label
    person_id = max(labels_list) + 1 if labels_list else 1
    person_folder = os.path.join(save_directory, str(person_id))

    if not os.path.exists(person_folder):
        os.makedirs(person_folder)
    
    # Save person details to the database
    save_person_to_db(int(person_id), name, surname, phone_number, cin, person_folder)

    return jsonify({"message": "Person added successfully and folder created successfully.", "id": int(person_id), "path_folder": person_folder}), 200

@app.route('/upload_images', methods=['POST'])
def upload_images():
    data = request.files.getlist('images')
    person_id = request.form.get('id')

    if not person_id:
        return jsonify({"error": "Person ID is required"}), 400

    # Fetch folder path from the database
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT folder_path FROM Persons WHERE id = ?", (int(person_id),))
    result = cursor.fetchone()
    conn.close()

    if not result:
        return jsonify({"error": "Person folder does not exist"}), 400

    person_folder = result[0]

    for img_file in data:
        image_path = os.path.join(person_folder, img_file.filename)
        img_file.save(image_path)
    
    return jsonify({"message": f"Images uploaded successfully to {person_folder}."}), 200

@app.route('/update_model', methods=['POST'])
def update_model():
    data = request.json
    person_id = data.get('id')

    if not person_id:
        return jsonify({"error": "Person ID is required"}), 400

    # Fetch folder path from the database
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT folder_path FROM Persons WHERE id = ?", (int(person_id),))
    result = cursor.fetchone()
    conn.close()

    if not result:
        return jsonify({"error": "Person folder does not exist"}), 400

    person_folder = result[0]
    new_person_images = [cv2.imread(os.path.join(person_folder, img)) for img in os.listdir(person_folder)]
    new_person_embeddings = [extract_face_embeddings(image) for image in new_person_images]
    new_person_embeddings = [embedding for embedding in new_person_embeddings if embedding is not None]

    if len(new_person_embeddings) == 0:
        return jsonify({"error": "No valid images found for the new person."}), 400

    global embeddings, labels, clf, le

    new_person_embeddings = np.array(new_person_embeddings)
    embeddings = np.vstack([embeddings, new_person_embeddings])
    labels = list(labels)

    labels.extend([int(person_id)] * new_person_embeddings.shape[0])

    le = LabelEncoder()
    labels_encoded = le.fit_transform(labels)

    unique_classes = np.unique(labels_encoded)
    if len(unique_classes) < 2:
        return jsonify({"error": "Number of classes must be greater than 1."}), 400

    clf = SVC(kernel='linear', probability=True)
    clf.fit(embeddings, labels_encoded)

    with open(embeddings_file, 'wb') as f:
        pickle.dump((embeddings, labels), f)

    with open(classifier_file, 'wb') as f:
        pickle.dump((clf, le), f)

    return jsonify({"message": "Model updated successfully."}), 200


@app.route('/recognize', methods=['POST'])
def recognize():
    try:
        image_bytes = request.get_data()
        image = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
        
        face_embedding = extract_face_embeddings(image)
        if face_embedding is not None:
            face_embedding = face_embedding.reshape(1, -1)
            predictions = clf.predict_proba(face_embedding)
            max_index = np.argmax(predictions)
            confidence = predictions[0][max_index]
            label = le.inverse_transform([max_index])[0]

            if confidence > 0.3:
                conn = get_db_connection()
                cursor = conn.cursor()
                cursor.execute("SELECT * FROM Persons WHERE id = ?", (int(label),))
                person_info = cursor.fetchone()
                conn.close()

                if person_info:
                    return jsonify({
                        "id": str(label),
                        "confidence": float(confidence),
                        "name": person_info.nom,
                        "surname": person_info.prenom,
                        "cin": person_info.cin,
                        "phone_number": person_info.numero_telephone
                    })
                else:
                    return jsonify({"error": "Person not found in database"}), 404
            else:
                return jsonify({"error": "Person not found in database"}), 404
        else:
            return jsonify({"error": "No face detected"})
    except Exception as e:
        return jsonify({"error": str(e)})


@app.route('/check_update', methods=['GET'])
def check_update():
    try:
        if os.path.exists(embeddings_file) and os.path.exists(classifier_file):
            return jsonify({"status": "Model is up-to-date"}), 200
        else:
            return jsonify({"status": "Model update failed"}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500
if __name__ == '__main__':
    app.run(debug=True)