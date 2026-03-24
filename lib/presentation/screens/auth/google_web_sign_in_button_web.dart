import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: web_only.renderButton(
        configuration: GSIButtonConfiguration(
          theme: GSIButtonTheme.outline,
          size: GSIButtonSize.large,
          text: GSIButtonText.continueWith,
          shape: GSIButtonShape.pill,
          minimumWidth: 260,
          logoAlignment: GSIButtonLogoAlignment.left,
        ),
      ),
    );
  }
}
