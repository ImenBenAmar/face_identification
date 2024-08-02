import 'package:flutter/material.dart';
import 'package:recognation_app/loginpage.dart'; // Assurez-vous que le chemin est correct

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Desktop App'),
        backgroundColor: Colors.teal, // Couleur de l'AppBar
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'back.jpg'), // Assurez-vous que l'image est dans le bon répertoire
            fit: BoxFit.cover, // Couvre toute la page
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.start, // Aligne les enfants en haut
          children: <Widget>[
            // Ajouter un espace en haut pour le texte "Welcome"
            SizedBox(height: 50.0),
            Container(
              margin: EdgeInsets.only(bottom: 50.0),
              child: Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 48.0, // Augmenter la taille de la police
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(
                      159, 9, 151, 104), // Couleur du texte pour le contraste
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, // Couleur de fond du bouton
                    foregroundColor:
                        Colors.white, // Couleur du texte du bouton en blanc
                    padding: EdgeInsets.symmetric(
                        vertical: 20.0,
                        horizontal: 40.0), // Augmenter la taille du bouton
                    textStyle: TextStyle(
                      fontSize: 20.0, // Augmenter la taille du texte du bouton
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
