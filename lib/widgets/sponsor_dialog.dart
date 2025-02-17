import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'custom_dialog.dart';

class SponsorDialog extends StatefulWidget {
  final Function(String amount, String payMethod) onPay;
  final Color selectedBgColor;
  final Color foregroundColor;
  final Color backgroundColor;

  const SponsorDialog({
    Key? key,
    required this.onPay,
    required this.selectedBgColor,
    required this.foregroundColor,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  State<SponsorDialog> createState() => _SponsorDialogState();
}

class _SponsorDialogState extends State<SponsorDialog> {
  String selectedAmount = '6.66'; // 默认金额
  String? sponsorAmount = '6.66'; // 选中的金额，null 表示未选中
  final TextEditingController _customAmountController = TextEditingController();
  bool isCustomAmount = false;
  bool showCustomInput = false; // 控制是否显示自定义金额输入框

  // 预设的赞助金额选项
  final List<String> amounts = ['6.66', '12.88', '25.88'];

  @override
  void initState() {
    super.initState();
    _customAmountController.addListener(_handleCustomAmountChange);
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _handleCustomAmountChange() {
    if (_customAmountController.text.isNotEmpty) {
      setState(() {
        selectedAmount = _customAmountController.text;
        sponsorAmount = null;
        isCustomAmount = true;
      });
    } else {
      setState(() {
        selectedAmount = '6.66';
        isCustomAmount = false;
      });
    }
  }

  void _handleAmountSelect(String amount) {
    setState(() {
      showCustomInput = false;
      isCustomAmount = false;
      _customAmountController.clear();

      // 如果点击已选中的金额，则取消选中，恢复默认值
      if (sponsorAmount == amount) {
        sponsorAmount = null;
        selectedAmount = '6.66';
      } else {
        // 否则选中新的金额
        sponsorAmount = amount;
        selectedAmount = amount;
      }
    });
  }

  void _handlePayment(String payMethod) {
    // 如果是自定义金额且输入框为空，显示提示
    if (showCustomInput && _customAmountController.text.isEmpty) {
      showHint('请输入自定义金额');
      return;
    }
    Navigator.of(context).pop();
    widget.onPay(selectedAmount, payMethod);
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: '感谢您的支持！',
      titleColor: widget.foregroundColor,
      cancelButtonText: '微信支付',
      confirmButtonText: '支付宝',
      conformButtonColor: widget.selectedBgColor,
      cancelButtonColor: widget.selectedBgColor,
      contentBackgroundColor: widget.backgroundColor,
      maxWidth: 380,
      isCancelClose: false,
      isConformClose: false,
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              '您的支持是我们继续改进的动力',
              style: TextStyle(
                color: widget.foregroundColor.withAlpha(178),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...amounts.map((amount) => _buildSponsorAmountButton(
                      amount,
                      isSelected: !isCustomAmount && sponsorAmount == amount,
                    )),
                // 自定义金额按钮
                _buildCustomButton(),
              ],
            ),
            if (showCustomInput) ...[
              const SizedBox(height: 8),
              _buildCustomAmountInput(),
            ],
          ],
        ),
      ),
      onCancel: () => _handlePayment('wxpay'),
      onConfirm: () => _handlePayment('alipay'),
    );
  }

  Widget _buildCustomButton() {
    return InkWell(
      onTap: () {
        setState(() {
          showCustomInput = !showCustomInput;
          if (!showCustomInput) {
            isCustomAmount = false;
            _customAmountController.clear();
            selectedAmount = '6.66';
            sponsorAmount = '6.66';
          } else {
            sponsorAmount = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: showCustomInput ? widget.selectedBgColor.withAlpha(25) : null,
          border: Border.all(
            color: showCustomInput ? widget.selectedBgColor : widget.selectedBgColor.withAlpha(128),
            width: showCustomInput ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: widget.selectedBgColor,
        ),
      ),
    );
  }

  Widget _buildCustomAmountInput() {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isCustomAmount ? widget.selectedBgColor.withAlpha(25) : null,
        border: Border.all(
          color: isCustomAmount ? widget.selectedBgColor : widget.selectedBgColor.withAlpha(128),
          width: isCustomAmount ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '￥',
            style: TextStyle(
              color: widget.selectedBgColor,
              fontSize: 14,
              fontWeight: isCustomAmount ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _customAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '自定义',
                hintStyle: TextStyle(
                  color: widget.selectedBgColor.withAlpha(128),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                isDense: true, // 使输入框更紧凑
              ),
              style: TextStyle(
                color: widget.selectedBgColor,
                fontSize: 14,
                fontWeight: isCustomAmount ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorAmountButton(String amount, {bool isSelected = false}) {
    return InkWell(
      onTap: () => _handleAmountSelect(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.selectedBgColor.withAlpha(25) : null,
          border: Border.all(
            color: isSelected ? widget.selectedBgColor : widget.selectedBgColor.withAlpha(128),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '￥$amount',
          style: TextStyle(
            color: widget.selectedBgColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
