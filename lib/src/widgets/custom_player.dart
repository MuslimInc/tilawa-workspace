import 'package:flutter/material.dart';

class CustomPlayerButton extends StatefulWidget {
  const CustomPlayerButton({
    required this.onTap,
    required this.index,
    required this.title,
    required this.color,
    required this.urlAudio,
  });
  final VoidCallback? onTap;
  final int index;
  final String title;
  final Color color;
  final String urlAudio;

  @override
  _CustomPlayerButtonState createState() => _CustomPlayerButtonState();
}

class _CustomPlayerButtonState extends State<CustomPlayerButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.90,
      height: 42,
      child: ElevatedButton(
        onPressed: widget.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF313130),
          // backgroundColor: color.withOpacity(0.04),
          elevation: 0.0,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          children: [
            Text(
              widget.index.toString(),
              style: TextStyle(
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.title.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                // color: color,
                fontSize: 15.0,
                fontWeight: FontWeight.normal,
              ),
            ),
            const Spacer(),
            // TextButton(
            //   onPressed: () => _pageManager.play(),
            //   style: TextButton.styleFrom(
            //     shape: CircleBorder(),
            //     backgroundColor: Color(0xFF3F4550),
            //     alignment: Alignment.center,
            //     visualDensity: VisualDensity.comfortable,
            //     // padding: EdgeInsets.zero,
            //   ),
            //   child: Icon(
            //     Icons.play_arrow,
            //     color: Colors.white,
            //   ),
            // ),

            const Icon(
              Icons.play_arrow,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
