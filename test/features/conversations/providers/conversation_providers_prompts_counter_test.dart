import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/core/providers/storage_providers.dart';
import 'package:localmind/core/storage/entities.dart';
import 'package:localmind/core/storage/objectbox_store.dart';
import 'package:localmind/features/conversations/providers/conversation_providers.dart';
import 'package:localmind/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

void main() {
  late _InMemoryConversationBox conversationBox;
  late _FakeStore fakeStore;
  late _FakeObjectBoxStore db;
  late ProviderContainer container;

  setUp(() {
    conversationBox = _InMemoryConversationBox();
    fakeStore = _FakeStore(conversationBox: conversationBox);
    db = _FakeObjectBoxStore(
      store: fakeStore,
      conversationBox: conversationBox,
    );
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'updateTokenCount preserves stored promptsProcessed when cache is stale',
    () async {
      // Limitation: a fully deterministic in-flight interleaving with
      // incrementPromptsProcessed cannot be driven here because the notifier
      // uses synchronous ObjectBox transactions and isolate-backed async reloads
      // without injectable scheduling hooks. This regression proves the core
      // invariant: updateTokenCount must not copy a stale cached
      // promptsProcessed back into the DB row it writes.
      await container.read(conversationsProvider.future);
      final notifier = container.read(conversationsProvider.notifier);
      final conversation = await notifier.createConversation(title: 'Counter');

      // Simulate a committed increment not yet reflected in the notifier cache
      // by advancing only the stored DB row.
      final storedEntity = conversationBox.entitiesById(conversation.id).single;
      storedEntity.promptsProcessed = 3;
      conversationBox.put(storedEntity);

      await notifier.updateTokenCount(conversation.id, 42);

      final persisted = conversationBox.entitiesById(conversation.id).single;
      expect(persisted.totalTokenCount, 42);
      expect(
        persisted.promptsProcessed,
        3,
        reason:
            'updateTokenCount must preserve the stored promptsProcessed from '
            'the DB row it writes, not overwrite it with a stale cached value',
      );

      final inState = container
          .read(conversationsProvider)
          .value!
          .firstWhere((c) => c.id == conversation.id);
      expect(inState.totalTokenCount, 42);
      expect(inState.promptsProcessed, 3);
    },
  );
}

class _FakeObjectBoxStore extends Fake implements ObjectBoxStore {
  _FakeObjectBoxStore({required this.store, required this.conversationBox});

  @override
  final Store store;

  @override
  final Box<ConversationEntity> conversationBox;
}

class _FakeStore extends Fake implements Store {
  _FakeStore({required this.conversationBox});

  final _InMemoryConversationBox conversationBox;
  final _EmptyMessageBox messageBox = _EmptyMessageBox();

  @override
  Box<T> box<T>() {
    if (T == ConversationEntity) {
      return conversationBox as Box<T>;
    }
    if (T == MessageEntity) {
      return messageBox as Box<T>;
    }
    throw UnimplementedError('No fake box for $T');
  }

  @override
  Future<R> runInTransactionAsync<R, P>(
    TxMode mode,
    R Function(Store, P) fn,
    P param,
  ) async {
    return fn(this, param);
  }

  @override
  R runInTransaction<R>(TxMode mode, R Function() fn) {
    return fn();
  }
}

class _InMemoryConversationBox extends Fake implements Box<ConversationEntity> {
  final List<ConversationEntity> _entities = [];
  int _nextId = 1;

  List<ConversationEntity> entitiesById(String id) =>
      _entities.where((e) => e.id == id).toList();

  @override
  List<ConversationEntity> getAll() => List<ConversationEntity>.from(_entities);

  @override
  int put(ConversationEntity object, {PutMode mode = PutMode.put}) {
    if (object.internalId == 0) {
      object.internalId = _nextId++;
      _entities.add(object);
    } else {
      final idx = _entities.indexWhere(
        (e) => e.internalId == object.internalId,
      );
      if (idx >= 0) {
        _entities[idx] = object;
      } else {
        _entities.add(object);
      }
    }
    return object.internalId;
  }

  @override
  QueryBuilder<ConversationEntity> query([Condition<ConversationEntity>? qc]) {
    return _ConversationQueryBuilder(_entities);
  }
}

class _ConversationQueryBuilder extends Fake
    implements QueryBuilder<ConversationEntity> {
  _ConversationQueryBuilder(this._entities);
  final List<ConversationEntity> _entities;

  @override
  Query<ConversationEntity> build() => _ConversationQuery(_entities);
}

class _ConversationQuery extends Fake implements Query<ConversationEntity> {
  _ConversationQuery(this._entities);
  final List<ConversationEntity> _entities;

  @override
  ConversationEntity? findFirst() => _entities.isEmpty ? null : _entities.last;

  @override
  List<ConversationEntity> find() => List<ConversationEntity>.from(_entities);

  @override
  void close() {}
}

class _EmptyMessageBox extends Fake implements Box<MessageEntity> {
  @override
  QueryBuilder<MessageEntity> query([Condition<MessageEntity>? qc]) {
    return _EmptyMessageQueryBuilder();
  }

  @override
  List<MessageEntity> getAll() => const [];
}

class _EmptyMessageQueryBuilder extends Fake
    implements QueryBuilder<MessageEntity> {
  @override
  Query<MessageEntity> build() => _EmptyMessageQuery();
}

class _EmptyMessageQuery extends Fake implements Query<MessageEntity> {
  @override
  List<MessageEntity> find() => const [];

  @override
  void close() {}
}
