import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'animals.dart';
import 'api.dart';
import 'colors.dart';
import 'petfinder_lib/petfinder.dart';
import 'protos/animals.pb.dart';
import 'widgets/pet_image_gallery.dart';

/// Shows detailed profile for the animal.
class DetailsPage extends StatefulWidget {
  DetailsPage({Key key, this.pet}) : super(key: key);

  final Animal pet;

  @override
  _DetailsPage createState() => _DetailsPage();
}

class _DetailsPage extends State<DetailsPage> {
  List<String> urls;
  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: key,
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: Text(widget.pet.info.name,
            style: const TextStyle(fontFamily: 'Raleway')),
      ),
      body: ListView(
        children: <Widget>[
          PetImageGallery(
            widget.pet.info.imgUrl,
            tag: widget.pet.info.apiId,
          ),
          _buildDogInfo(widget.pet.info),
          Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text("Comments about ${widget.pet.info.name}:",
                style: const TextStyle(fontFamily: 'Raleway', fontSize: 20.0)),
          ),
          _fetchAndBuildComments(key),
          Divider(),
          _buildOptionTagSection(widget.pet.info),
          _buildAdoptInfo(),
          !widget.pet.info.hasId()
              ? SizedBox()
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Tell them you want to adopt ${widget.pet.info.name}"
                    " whose ID is ${widget.pet.info.id}.",
                    textAlign: TextAlign.center,
                  ),
                ),
        ],
      ),
    );
  }

  _populateUrls(String description) {
    urls = List<String>();
    var urlMatches = RegExp(kUrlRegex).allMatches(description);
    for (Match m in urlMatches) {
      urls.add(m.group(0));
    }
  }

  Widget _fetchAndBuildComments(GlobalKey<ScaffoldState> key) {
    if (widget.pet.description != null) {
      _populateUrls(widget.pet.description);
      return _buildComments(widget.pet.description, urls, key);
    }
    return FutureBuilder(
      future: getDetailsAbout(widget.pet),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Center(child: Text('Wait..'));
          case ConnectionState.waiting:
            return Center(child: Text('Loading...'));
          default:
            if (snapshot.hasError)
              return Center(
                child: Text('Couldn\'t get the comments :( '),
              );
            else {
              _populateUrls(snapshot.data);
              return _buildComments(snapshot.data, urls, key);
            }
        }
      },
    );
  }

  Widget _buildComments(
      String comments, List<String> urls, GlobalKey<ScaffoldState> key) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: RichText(
            text: TextSpan(
              text: comments,
              style: Theme.of(context).textTheme.body1,
            ),
          ),
        ),
        _buildLinkSection(urls, key),
      ],
    );
  }

  Widget _createInfoRow(String title, String item) {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Text(
            title,
            style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 20.0,
                fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
            child: Text(item,
                style: const TextStyle(fontFamily: 'Raleway', fontSize: 20.0))),
      ],
    );
  }

  Widget _buildDogInfo(AnimalData pet) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    child: Text(pet.breed,
                        style: const TextStyle(
                            fontFamily: 'Raleway', fontSize: 20.0))),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                    child: Text("${pet.gender} • ${pet.age}",
                        style: const TextStyle(
                            fontFamily: 'Raleway', fontSize: 20.0))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTagSection(AnimalData pet) {
    if (pet.options == null || pet.options.isEmpty) return SizedBox();
    return Column(
      children: <Widget>[
        Text("Pet Tags"),
        _buildOptionTags(),
        Divider(),
      ],
    );
  }

  Widget _buildOptionTags() {
    return Container(
      height: 40.0,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: widget.pet.info.options.map((option) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              option,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kPetThemecolor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUrlTags(List<String> urls, GlobalKey<ScaffoldState> key) {
    return Container(
      height: 50.0,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: urls.map((String url) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () async {
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: url));
                key.currentState.showSnackBar(SnackBar(
                  content: Text("Copied!"),
                ));
              },
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    url,
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      color: Theme.of(context).indicatorColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShelterDescription(ShelterInformation shelter) {
    if (shelter == null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Shelter opted out of giving information :("),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            shelter.phone.trim() == ""
                ? SizedBox()
                : ActionChip(
                    backgroundColor: Colors.white,
                    elevation: 1.5,
                    label: Row(
                      children: <Widget>[
                        Icon(
                          Icons.phone,
                          color: Colors.blue,
                        ),
                        Text(shelter.phone),
                      ],
                    ),
                    onPressed: () async {
                      String url = "tel://${shelter.phone}";
                      if (await canLaunch(url)) launch(url);
                    }),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ActionChip(
                backgroundColor: Colors.white,
                elevation: 1.5,
                label: Row(
                  children: <Widget>[
                    Icon(
                      Icons.email,
                      color: Colors.red,
                    ),
                    Text(shelter.email),
                  ],
                ),
                onPressed: () async {
                  String url = "mailto://${shelter.email}";
                  if (await canLaunch(url)) launch(url);
                }),
          ],
        ),
        _shelterActionChip(
            Icon(
              Icons.location_on,
              color: Colors.green,
            ),
            Expanded(
              child: Text(
                "${shelter.name}, ${shelter.location}",
                overflow: TextOverflow.ellipsis,
              ),
            ), () async {
          String search = Uri.encodeComponent("${shelter.name}, "
              "${shelter.location}");
          String url = "geo:0,0?q=$search";
          if (await canLaunch(url)) launch(url);
        }),
        shelter.distance != -1
            ? Text('${shelter.distance} miles away.')
            : SizedBox(),
      ],
    );
  }

  Widget _shelterActionChip(Icon icon, Widget body, Function onPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ActionChip(
          backgroundColor: Colors.white,
          elevation: 1.5,
          label: Container(
            constraints: BoxConstraints(maxWidth: 300),
            child: Row(
              children: <Widget>[
                icon,
                body,
              ],
            ),
          ),
          onPressed: onPressed,
        )
      ],
    );
  }

  Widget _buildAdoptInfo() {
    return Column(
      children: <Widget>[
        Text(
          "Adopt ${widget.pet.info.name}!",
          style: const TextStyle(
              fontFamily: "Raleway",
              fontSize: 23.0,
              fontWeight: FontWeight.bold),
        ),
        FutureBuilder(
          future: getShelterInformation(widget.pet.info.shelterId),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return Text('Wait..');
              case ConnectionState.waiting:
                return Text('Loading shleter information...');
              default:
                if (snapshot.hasError)
                  return new Text(
                      'Couldn\'t get the information :( ${snapshot.error}');
                else
                  return _buildShelterDescription(snapshot.data);
            }
          },
        ),
      ],
    );
  }

  Widget _buildLinkSection(List<String> urls, key) {
    if (urls.isEmpty) return SizedBox();
    return Column(
      children: <Widget>[
        Divider(),
        Text("Links:"),
        _buildUrlTags(urls, key),
        Text("Long press link to copy",
            style: const TextStyle(color: Colors.grey, fontSize: 12.0))
      ],
    );
  }
}
