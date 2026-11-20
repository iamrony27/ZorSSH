import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aetherssh/core/theme/app_theme.dart';

class UpiDonationSheet {
  /// The official developer UPI ID
  static const String currentUpiId = '7074018142@ptani';

  static void show(BuildContext context) {
    final upiUri = Uri.parse(
      'upi://pay?pa=$currentUpiId&pn=Zor%20SSH%20Developer&cu=INR&tn=Support%20Zor%20SSH',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F131A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                LucideIcons.heartHandshake,
                color: Color(0xFF00E676),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Support Zor SSH',
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Zor SSH is an independent, ad-free SSH utility. If you love the features, your support helps maintain active updates and server engines!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // UPI ID Display Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161C26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.badgeCheck,
                    color: Color(0xFF00E676),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPI ID',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentUpiId,
                          style: GoogleFonts.firaCode(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.copy,
                      color: Color(0xFF00E676),
                      size: 18,
                    ),
                    tooltip: 'Copy UPI ID',
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: currentUpiId));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('UPI ID copied to clipboard!'),
                          backgroundColor: Color(0xFF00E676),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pay with UPI App Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: const Color(0xFF050505),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (await canLaunchUrl(upiUri)) {
                    await launchUrl(upiUri, mode: LaunchMode.externalApplication);
                  } else {
                    Clipboard.setData(const ClipboardData(text: currentUpiId));
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No UPI app detected. UPI ID copied to clipboard.',
                          ),
                          backgroundColor: Color(0xFF00E676),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(LucideIcons.send, size: 18),
                label: Text(
                  'Pay with UPI App',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
