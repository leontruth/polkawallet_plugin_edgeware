import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_edgeware/polkawallet_plugin_edgeware.dart';
import 'package:polkawallet_plugin_edgeware/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/utils/format.dart';

class RebondPage extends StatefulWidget {
  RebondPage(this.plugin, this.keyring);
  static final String route = '/staking/rebond';
  final PluginEdgeware plugin;
  final Keyring keyring;
  @override
  _RebondPageState createState() => _RebondPageState();
}

class _RebondPageState extends State<RebondPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_edgeware, 'common');
    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_edgeware, 'staking');
    final symbol = widget.plugin.networkState.tokenSymbol[0];
    final decimals = widget.plugin.networkState.tokenDecimals[0];

    BigInt redeemable = BigInt.zero;
    if (widget.plugin.store.staking.ownStashInfo != null &&
        widget.plugin.store.staking.ownStashInfo.stakingLedger != null) {
      redeemable = BigInt.parse(widget
          .plugin.store.staking.ownStashInfo.account.redeemable
          .toString());
    }
    BigInt unlocking = widget.plugin.store.staking.accountUnlockingTotal;
    unlocking -= redeemable;

    final available = Fmt.bigIntToDouble(unlocking, decimals);

    return Scaffold(
      appBar: AppBar(
        title: Text(dicStaking['action.bondExtra']),
        centerTitle: true,
      ),
      body: Builder(builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: <Widget>[
                      AddressFormItem(
                        widget.keyring.current,
                        label: dicStaking['controller'],
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: dic['amount'],
                          labelText:
                              '${dic['amount']} (${dicStaking['available']}: ${Fmt.priceFloor(
                            available,
                            lengthMax: 4,
                          )} $symbol)',
                        ),
                        inputFormatters: [UI.decimalInputFormatter(decimals)],
                        controller: _amountCtrl,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v.isEmpty) {
                            return dic['amount.error'];
                          }
                          if (double.parse(v.trim()) > available) {
                            return dic['amount.low'];
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: TxButton(
                  getTxParams: () async {
                    if (_formKey.currentState.validate()) {
                      final inputAmount = _amountCtrl.text.trim();
                      return TxConfirmParams(
                        txTitle: dicStaking['action.rebond'],
                        module: 'staking',
                        call: 'rebond',
                        txDisplay: {"amount": '$inputAmount $symbol'},
                        params: [
                          // "amount"
                          Fmt.tokenInt(inputAmount, decimals).toString(),
                        ],
                      );
                    }
                    return null;
                  },
                  onFinish: (Map res) {
                    if (res != null) {
                      Navigator.of(context).pop(res);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
