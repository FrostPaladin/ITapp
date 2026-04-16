import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koto_zayavochnik/core/api/api_client.dart';

// Events
abstract class TicketsEvent {}

class LoadTickets extends TicketsEvent {
  final String status;
  LoadTickets({this.status = 'open'});
}

class CreateTicket extends TicketsEvent {
  final Map<String, dynamic> data;
  CreateTicket(this.data);
}

class UpdateTicket extends TicketsEvent {
  final String id;
  final Map<String, dynamic> data;
  UpdateTicket(this.id, this.data);
}

class DeleteTicket extends TicketsEvent {
  final String id;
  DeleteTicket(this.id);
}

class AddComment extends TicketsEvent {
  final String ticketId;
  final String comment;
  AddComment(this.ticketId, this.comment);
}

// States
abstract class TicketsState {}

class TicketsInitial extends TicketsState {}

class TicketsLoading extends TicketsState {}

class TicketsLoaded extends TicketsState {
  final List<Map<String, dynamic>> tickets;
  TicketsLoaded(this.tickets);
}

class TicketsError extends TicketsState {
  final String message;
  TicketsError(this.message);
}

class TicketDetailLoaded extends TicketsState {
  final Map<String, dynamic> ticket;
  TicketDetailLoaded(this.ticket);
}

// BLoC
class TicketsBloc extends Bloc<TicketsEvent, TicketsState> {
  final ApiClient _api;
  
  TicketsBloc(this._api) : super(TicketsInitial()) {
    on<LoadTickets>((event, emit) async {
    emit(TicketsLoading());
    try {
      final response = await _api.getTickets();
      
      final List<Map<String, dynamic>> tickets = [];
      for (var item in response) {
        if (item is Map) {
          tickets.add(Map<String, dynamic>.from(item));
      }
    }
    
    // Фильтруем по статусу (если не 'all')
    final filtered = event.status == 'all'
        ? tickets
        : tickets.where((t) => t['status'] == event.status).toList();
    
    emit(TicketsLoaded(filtered));
  } catch (e) {
    emit(TicketsError(e.toString()));
  }
});
    
    on<CreateTicket>((event, emit) async {
      try {
        await _api.createTicket(event.data);
        add(LoadTickets()); // Перезагружаем список
      } catch (e) {
        emit(TicketsError(e.toString()));
      }
    });
    
    on<UpdateTicket>((event, emit) async {
      try {
        await _api.updateTicket(event.id, event.data);
        add(LoadTickets());
      } catch (e) {
        emit(TicketsError(e.toString()));
      }
    });
    
    on<DeleteTicket>((event, emit) async {
      try {
        await _api.deleteTicket(event.id);
        add(LoadTickets());
      } catch (e) {
        emit(TicketsError(e.toString()));
      }
    });
    
    on<AddComment>((event, emit) async {
      try {
        await _api.addComment(event.ticketId, event.comment);
      } catch (e) {
        emit(TicketsError(e.toString()));
      }
    });
  }
}