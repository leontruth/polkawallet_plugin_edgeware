import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_edgeware/polkawallet_plugin_edgeware.dart';
import 'package:polkawallet_plugin_edgeware/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class UnBondPage extends StatefulWidget {
  UnBondPage(this.plugin, this.keyring);
  static final String route = '/staking/unbond';
  final PluginEdgeware plugin;
  final Keyring keyring;
  @override
  _UnBondPageState createState() => _UnBondPageState();
}

class _UnBondPageState extends State<UnBondPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_edgeware, 'common');
    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_edgeware, 'staking');
    final symbol = widget.plugin.networkState.tokenSymbol[0];
    final decimals = widget.plugin.networkState.tokenDecimals[0];

    double bonded = 0;
    if (widget.plugin.store.staking.ownStashInfo != null) {
      bonded = Fmt.bigIntToDouble(
          BigInt.parse(widget
              .plugin.store.staking.ownStashInfo.stakingLedger['active']
              .toString()),
          decimals);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dicStaking['action.unbond']),
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
                              '${dic['amount']} (${dicStaking['bonded']}: ${Fmt.priceFloor(
                            bonded,
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
                          if (double.parse(v.trim()) > bonded) {
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
                        txTitle: dicStaking['action.unbond'],
                        module: 'staking',
                        call: 'unbond',
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
