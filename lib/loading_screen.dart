import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      color: Color(0xFF2E3F7F),
                      strokeWidth: 3,
                      backgroundColor: Color(0xFFE5E9F5),
                    ),
                  ),
                  Icon(Icons.translate, size: 40, color: Color(0xFF41C3E5)),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Loading your experience...",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF404B69),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
