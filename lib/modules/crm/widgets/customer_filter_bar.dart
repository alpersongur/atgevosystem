import 'package:flutter/material.dart';

class CustomerFilterBar extends StatefulWidget {
  const CustomerFilterBar({
    super.key,
    required this.onQueryChanged,
    this.initialQuery,
    this.trailing,
  });

  final ValueChanged<String> onQueryChanged;
  final String? initialQuery;
  final Widget? trailing;

  @override
  State<CustomerFilterBar> createState() => _CustomerFilterBarState();
}

class _CustomerFilterBarState extends State<CustomerFilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Müşteri ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Filtreyi temizle',
                        onPressed: () {
                          _controller.clear();
                          widget.onQueryChanged('');
                          setState(() {});
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                widget.onQueryChanged(value);
                setState(() {});
              },
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 12),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}
