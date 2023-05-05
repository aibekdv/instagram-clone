import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insta_clone/common/firebase_consts.dart';
import 'package:insta_clone/feature/data/models/user/user_model.dart';
import 'package:insta_clone/feature/domain/entities/user/user_entity.dart';

import 'remote_data_source.dart';

class FirebaseRemoteDataSourceImpl implements FirebaseRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  FirebaseRemoteDataSourceImpl(
      {required this.firestore, required this.firebaseAuth});

  @override
  Future<void> createUser(UserEntity user) async {
    final userCollection = firestore.collection(FirebaseConsts.users);
    final uid = await getCurrentUid();

    userCollection.doc(uid).get().then((userDoc) {
      final newUser = UserModel(
        uid: uid,
        bio: user.bio,
        email: user.email,
        followers: user.followers,
        following: user.following,
        name: user.name,
        profileUrl: user.profileUrl,
        totalFollowers: user.totalFollowers,
        totalFollowing: user.totalFollowing,
        totalPosts: user.totalPosts,
        username: user.username,
        website: user.website,
      ).toJson();

      if (!userDoc.exists) {
        userCollection.doc(uid).set(newUser);
      } else {
        userCollection.doc(uid).update(newUser);
      }
    }).catchError((onError) {
      toast(onError.toString());
    });
  }

  @override
  Future<String> getCurrentUid() async => firebaseAuth.currentUser!.uid;

  @override
  Stream<List<UserEntity>> getSingleUser(String uid) {
    final userCollection = firestore
        .collection(FirebaseConsts.users)
        .where("uid", isEqualTo: uid)
        .limit(1);

    return userCollection.snapshots().map(
          (querySnapshot) =>
              querySnapshot.docs.map((e) => UserModel.fromSnapshot(e)).toList(),
        );
  }

  @override
  Stream<List<UserEntity>> getUsers(UserEntity user) {
    final userCollection = firestore.collection(FirebaseConsts.users);

    return userCollection.snapshots().map(
          (querySnapshot) =>
              querySnapshot.docs.map((e) => UserModel.fromSnapshot(e)).toList(),
        );
  }

  @override
  Future<bool> isSignIn() async => firebaseAuth.currentUser?.uid != null;

  @override
  Future<void> signIn(UserEntity user) async {
    try {
      if (user.email!.isNotEmpty || user.password!.isNotEmpty) {
        await firebaseAuth.signInWithEmailAndPassword(
            email: user.email!, password: user.password!);
      } else {
        print("Field can't be empty");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        toast("User not found");
      } else if (e.code == 'wrong-password') {
        toast("Ivalid email or password");
      }
    }
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<void> signUp(UserEntity user) async {
    try {
      await firebaseAuth
          .createUserWithEmailAndPassword(
        email: user.email!,
        password: user.password!,
      )
          .then(
        (value) async {
          if (value.user?.uid != null) {
            await createUser(user);
          }
        },
      );
      return;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        toast("Email is already exist");
      } else {
        toast("Somthing wrong");
      }
    }
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    final userCollection = firestore.collection(FirebaseConsts.users);
    Map<String, dynamic> userInformation = {};

    if (user.bio != '' && user.bio != null) {
      userInformation['bio'] = user.bio;
    }

    if (user.name != '' && user.name != null) {
      userInformation['name'] = user.name;
    }

    if (user.profileUrl != '' && user.profileUrl != null) {
      userInformation['profileUrl'] = user.profileUrl;
    }

    if (user.totalFollowers != null) {
      userInformation['totalFollowers'] = user.totalFollowers;
    }

    if (user.totalFollowing != null) {
      userInformation['totalFollowing'] = user.totalFollowing;
    }

    if (user.totalPosts != null) {
      userInformation['totalPosts'] = user.totalPosts;
    }

    if (user.website != '' && user.website != null) {
      userInformation['website'] = user.website;
    }

    userCollection.doc(user.uid).update(userInformation);
  }
}
