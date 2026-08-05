import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

enum CustomerSortOption {
  nameAsc,
  newest,
  highestDue,
  mostActive,
}

class CustomerFilterOptions {
  final String statusFilter; // 'all', 'active', 'inactive'
  final CustomerSortOption sortOption;
  final String areaQuery;

  CustomerFilterOptions({
    this.statusFilter = 'all',
    this.sortOption = CustomerSortOption.nameAsc,
    this.areaQuery = '',
  });

  CustomerFilterOptions copyWith({
    String? statusFilter,
    CustomerSortOption? sortOption,
    String? areaQuery,
  }) {
    return CustomerFilterOptions(
      statusFilter: statusFilter ?? this.statusFilter,
      sortOption: sortOption ?? this.sortOption,
      areaQuery: areaQuery ?? this.areaQuery,
    );
  }
}

class CustomerFilterBottomSheet extends StatefulWidget {
  final CustomerFilterOptions currentOptions;
  final ValueChanged<CustomerFilterOptions> onApply;

  const CustomerFilterBottomSheet({
    super.key,
    required this.currentOptions,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required CustomerFilterOptions currentOptions,
    required ValueChanged<CustomerFilterOptions> onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerFilterBottomSheet(
        currentOptions: currentOptions,
        onApply: onApply,
      ),
    );
  }

  @override
  State<CustomerFilterBottomSheet> createState() => _CustomerFilterBottomSheetState();
}

class _CustomerFilterBottomSheetState extends State<CustomerFilterBottomSheet> {
  late String _statusFilter;
  late CustomerSortOption _sortOption;
  late TextEditingController _areaController;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.currentOptions.statusFilter;
    _sortOption = widget.currentOptions.sortOption;
    _areaController = TextEditingController(text: widget.currentOptions.areaQuery);
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Filter & Sort Customers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _statusFilter = 'all';
                    _sortOption = CustomerSortOption.nameAsc;
                    _areaController.clear();
                  });
                },
                child: const Text('Reset All', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Customer Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterChip('All Customers', 'all', _statusFilter == 'all', () {
                setState(() => _statusFilter = 'all');
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Active Only', 'active', _statusFilter == 'active', () {
                setState(() => _statusFilter = 'active');
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Inactive', 'inactive', _statusFilter == 'inactive', () {
                setState(() => _statusFilter = 'inactive');
              }),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip('Customer Name (A-Z)', CustomerSortOption.nameAsc),
              _buildSortChip('Newest Customer', CustomerSortOption.newest),
              _buildSortChip('Highest Pending Dues', CustomerSortOption.highestDue),
              _buildSortChip('Most Active Cans', CustomerSortOption.mostActive),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Filter by Area / Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _areaController,
            decoration: InputDecoration(
              hintText: 'Enter street, building, or area name...',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Apply Filters',
                  onPressed: () {
                    widget.onApply(
                      CustomerFilterOptions(
                        statusFilter: _statusFilter,
                        sortOption: _sortOption,
                        areaQuery: _areaController.text.trim(),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildSortChip(String label, CustomerSortOption option) {
    final isSelected = _sortOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _sortOption = option);
      },
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}
