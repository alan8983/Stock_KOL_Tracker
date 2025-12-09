import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../domain/providers/repository_providers.dart';

/// Ticker 自動完成輸入框
/// 從本地 Stocks 表搜尋並提供建議
class TickerAutocompleteField extends ConsumerStatefulWidget {
  final String? initialValue;
  final ValueChanged<String?>? onChanged;

  const TickerAutocompleteField({
    super.key,
    this.initialValue,
    this.onChanged,
  });

  @override
  ConsumerState<TickerAutocompleteField> createState() =>
      _TickerAutocompleteFieldState();
}

class _TickerAutocompleteFieldState
    extends ConsumerState<TickerAutocompleteField> {
  TextEditingController? _controller;
  List<Stock> _suggestions = [];

  Future<void> _searchStocks(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final stockRepo = ref.read(stockRepositoryProvider);
    final results = await stockRepo.searchStocks(query);
    setState(() => _suggestions = results);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Stock>(
      initialValue: widget.initialValue != null
          ? TextEditingValue(text: widget.initialValue!)
          : null,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _controller = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: '投資標的 (Ticker)',
            hintText: '例如: AAPL, TSLA',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            _searchStocks(value);
            widget.onChanged?.call(value.isEmpty ? null : value);
          },
          onSubmitted: (value) => onFieldSubmitted(),
        );
      },
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Stock>.empty();
        }
        await _searchStocks(textEditingValue.text);
        return _suggestions;
      },
      displayStringForOption: (option) => option.ticker,
      onSelected: (option) {
        _controller?.text = option.ticker;
        widget.onChanged?.call(option.ticker);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final stock = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(stock.ticker),
                    subtitle: stock.name != null ? Text(stock.name!) : null,
                    onTap: () => onSelected(stock),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
