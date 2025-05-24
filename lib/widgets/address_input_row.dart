import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vru_safety_app/bloc/navigation_bloc.dart';
import 'package:vru_safety_app/bloc/navigation_event.dart';
import 'package:vru_safety_app/bloc/navigation_state.dart';

class AddressInputRow extends StatelessWidget {
  final TextEditingController addressController;

  const AddressInputRow({super.key, required this.addressController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Destination address',
                  border: OutlineInputBorder(),
                ),
                onChanged: (input) =>
                    context.read<NavigationBloc>().add(UpdateSuggestions(input)),
                onSubmitted: (_) {
                  context
                      .read<NavigationBloc>()
                      .add(SearchAddress(addressController.text));
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.routeLoading
                  ? null
                  : () {
                      context
                          .read<NavigationBloc>()
                          .add(SearchAddress(addressController.text));
                    },
              child: state.routeLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Route'),
            ),
          ],
        );
      },
    );
  }
}
