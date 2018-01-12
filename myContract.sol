pragma solidity ^0.4.15;

contract MMGA {

  //A comment can be created by a platform on behalf of a user or directly by a user. The authorDomain address therefore can be from a platform (domain) or from a specific user.
  //In case the address is from a platform, authorId can further be set to identity the user within the platform
  struct Comment {
    address authorDomain;
    bytes32 authorId;
    bytes32 textHash;

    //In case comment refers to specific passage. begIndex should be set to -1 in case it doesn't
    int32 begIndex;
    int32 endIndex;
    Comment[] parts;
  }

  struct Article {
    //Same logic as in Comment
    address creatorDomain;
    bytes32 creator;

    int32 timestamp;
    bytes32 uriHash;
    bytes32 titleHash;
    bytes32 authorHash;
    bool authorMapped;
    uint authorIndex;
    Comment[] comments;
  }

  
  address contractOwner;
  //Map author ID to array index
  string[] public authors;
  Article[] public articles;

  function MMGA() {
    contractOwner = msg.sender;
  }

  function addArticle(int32 myTimestamp, bytes32 myUriHash, bytes32 myTitleHash, bytes32 myAuthorHash) {
    require(!articleExists(myUriHash, myTimestamp));

    Article tempArticle = Article({
        creatorDomain: msg.sender,
        timestamp: myTimestamp,
        uriHash: myUriHash,
        titleHash: myTitleHash,
        authorHash: myAuthorHash
      });

    articles.push(tempArticle);

  }
  function addArticle(bytes32 myCreator, int32 myTimestamp, bytes32 myUriHash, bytes32 myTitleHash, bytes32 myAuthorHash) {
    require(!articleExists(myUriHash, myTimestamp));

    articles.push(Article({
        creatorDomain: msg.sender,
        creator: myCreator,
        timestamp: myTimestamp,
        uriHash: myUriHash,
        titleHash: myTitleHash,
        authorHash: myAuthorHash
      }));

  }

  function setAuthorInArticle(int articleIndex, uint16 authorIndex) {
    //Author can only be set by the creator of the article
    require(msg.sender == article.creator);
    require(articleIndex < articles.length);

    Article article = articles[articleIndex];
    //Author can only be set if no comments have been done yet
    require(article.comments.length == 0);

    article.authorMapped = true;
    article.authorIndex = authorIndex;

  }

  function addAuthor(string name) {
      require(!authorExists(name));
      authors.push(name);
  }



  //begIndex = -1 means comment does not refer to passage in text
  function addComment(int articleIndex, bytes32 myTextHash, uint32 myBegIndex, uint32 myEndIndex) {
    require(articleIndex < articles.length);
    require(myTextHash.length != 0);
    if(myBegIndex != -1) {
      require(myBegIndex < myEndIndex);
    }

    Article article = articles[articleIndex];
    article.comments.push(Comment({
        authorDomain: msg.sender,
        textHash: myTextHash,
        begIndex: myBegIndex,
        endIndex: myEndIndex
      }));

  }
  
  //begIndex = -1 means comment does not refer to passage in text
  //For domain comment (added on behalf of someone)
  function addComment(int articleIndex, bytes32 myAuthorId, bytes32 myTextHash, int32 myBegIndex, int32 myEndIndex) {
    require(articleIndex < articles.length);
    require(myTextHash.length != 0);
    require(myAuthorId.length != 0);
    if(myBegIndex != -1) {
      require(myBegIndex < myEndIndex);
    }

    Article article = articles[articleIndex];
    article.comments.push(Comment({
        authorDomain: msg.sender,
        authorId: myAuthorId,
        textHash: myTextHash,
        begIndex: myBegIndex,
        endIndex: myEndIndex
      }));

  }
  
  function addNestedCommment(int articleIndex, int commentIndex, bytes32 myTextHash, int32 myBegIndex, int32 myEndIndex) {
    require(articleIndex < articles.length);
    require(myTextHash.length != 0);
    if(myBegIndex != -1) {
      require(myBegIndex < myEndIndex);
    }

    Article article = articles[articleIndex];

    require(commentIndex < article.comments.length);

    article.comments[commentIndex].push(Comment({
        authorDomain: msg.sender,
        textHash: myTextHash,
        begIndex: myBegIndex,
        endIndex: myEndIndex
      }));

  }

  function addNestedCommment(int articleIndex, int commentIndex, bytes32 myAuthorId, bytes32 myTextHash, int32 myBegIndex, int32 myEndIndex) {
    require(articleIndex < articles.length);
    require(myTextHash.length != 0);
    if(myBegIndex != -1) {
      require(myBegIndex < myEndIndex);
    }

    Article article = articles[articleIndex];

    require(commentIndex < article.comments.length);

    article.comments[commentIndex].push(Comment({
        authorDomain: msg.sender,
        authorId: myAuthorId,
        textHash: myTextHash,
        begIndex: myBegIndex,
        endIndex: myEndIndex
      }));

  }

  //Returns -1 if author does not exist
  function getAuthorIndexFromName(string name) constant returns (int) {
    for(uint i = 0; i < authors.length; i++) {
      if(keccak256(authors[i]) == keccak256(name)) {
        return i;
      }
    }
    return -1;
  }

  function getAuthorNameFromIndex(uint ind) constant returns (string) {
    require(ind < authors.length);
    return authors[ind];
  }

  function authorExists(string name) constant returns (bool) {
    for(uint i = 0; i < authors.length; i++) {
      if(keccak256(authors[i]) == keccak256(name)) {
        return true;
      }
    }
    return false;
  }

  //Returns -1 if article does not exist
  //Gets next article index given possible hash colision
  function getNextArticleIndex(uint start, bytes32 uriHash) constant returns (int) {
    if(start >= articles.length) {
      return -1;
    }
    for(uint i = start; i < articles.length; i++) {
      if(articles[i].uriHash == uriHash) {
        return i;
      }
    }
    return -1;
  }

  function articleExists(bytes32 uriHash, int32 timestamp) constant returns (bool) {
    for(uint i = 0; i < articles.length; i++) {
      if(articles[i].uriHash == uriHash && articles[i].timestamp == timestamp) {
        return true;
      }
    }
    return false;
  }
}