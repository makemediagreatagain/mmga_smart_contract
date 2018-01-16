pragma solidity ^0.4.15;

contract MMGA {

  //A comment can be created by a platform on behalf of a user or directly by a user. The authorDomain address therefore can be from a platform (domain) or from a specific user.
  //In case the address is from a platform, authorId can further be set to identity the user within the platform
  struct Comment {
    address authorDomain;
    bytes32 authorId;
    bytes32 textHash;

    //In case comment refers to specific passage. begIndex should be set to -1 in case it doesn't
    int64 begIndex;
    uint32 endIndex;
    uint256[] parts;
  }

  struct SubComment {
    bytes32 textHash;
    //In case comment refers to a specific passage. begIndex should be set to -1 in case it doesn't
    int64 begIndex;
    uint32 endIndex;
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
    uint256[] comments;
  }



  
  address contractOwner;
  //Map author ID to array index
  string[] public authors;
  Article[] public articles;
  Comment[] public comments;
  SubComment[] public subComments;

  function MMGA() public {
    contractOwner = msg.sender;
  }


  function addArticle(int32 myTimestamp, bytes32 myUriHash, bytes32 myTitleHash, bytes32 myAuthorHash) public {
    require(!articleExists(myUriHash, myTimestamp));

    articles.push(Article({
        creatorDomain: msg.sender,
        creator: 0,
        timestamp: myTimestamp,
        uriHash: myUriHash,
        titleHash: myTitleHash,
        authorHash: myAuthorHash,
        authorMapped: false,
        authorIndex: 0,
        comments: new uint256[](0)
      }));

  }

  function addArticle2(bytes32 myCreator, int32 myTimestamp, bytes32 myUriHash, bytes32 myTitleHash, bytes32 myAuthorHash) public {
    require(!articleExists(myUriHash, myTimestamp));

    articles.push(Article({
        creatorDomain: msg.sender,
        creator: myCreator,
        timestamp: myTimestamp,
        uriHash: myUriHash,
        titleHash: myTitleHash,
        authorHash: myAuthorHash,
        authorMapped: false,
        authorIndex: 0, 
        comments: new uint256[](0)
      }));

  }
    
   function addAuthor(string name) public {
      require(!authorExists(name));
      authors.push(name);
  }

  function setAuthorInArticle(uint articleIndex, uint16 authorIndex) public {
    //Author can only be set by the creator of the article
    require(msg.sender == article.creatorDomain);
    require(articleIndex < articles.length);
    require(authorIndex < authors.length);

    Article storage article = articles[articleIndex];
    //Author can only be set if no comments have been done yet
    require(article.comments.length == 0);

    article.authorMapped = true;
    article.authorIndex = authorIndex;

  }

  function removeAuthorFromArticle(uint articleIndex) public {
    require(msg.sender == article.creatorDomain);
    require(articleIndex < articles.length);

    Article storage article = articles[articleIndex];
    require(article.authorMapped == true);
    require(article.comments.length == 0);

    article.authorMapped = false;

  }

  //begIndex = -1 means comment does not refer to passage in text
  function addComment(uint articleIndex, bytes32 myTextHash, int32 myBegIndex, uint32 myEndIndex) public {
    require(articleIndex < articles.length);
    require(myTextHash.length != 0);
    if(myBegIndex != -1) {
      require(uint(myBegIndex) < myEndIndex);
    }

    Article storage article = articles[articleIndex];
    uint256 index = comments.length;
    comments.push(Comment({
        authorDomain: msg.sender,
        authorId: 0,
        textHash: myTextHash,
        begIndex: myBegIndex,
        endIndex: myEndIndex,
        parts: new uint256[](0)
      }));
    article.comments.push(index);

  }
  
  //begIndex = -1 means comment does not refer to passage in text
  //For domain comment (added on behalf of someone)
  function addComment2(uint articleIndex, bytes32 myAuthorId, bytes32 myTextHash, int32 myBegIndex, uint32 myEndIndex) public {
    require(articleIndex < articles.length);
    require(myTextHash.length != 0);
    require(myAuthorId.length != 0);
    if(myBegIndex != -1) {
      require(uint(myBegIndex) < myEndIndex);
    }

    Article storage article = articles[articleIndex];
    uint256 index = comments.length;
    comments.push(Comment({
        authorDomain: msg.sender,
        authorId: myAuthorId,
        textHash: myTextHash,
        begIndex: myBegIndex,
        endIndex: myEndIndex,
        parts: new uint256[](0)
      }));
    article.comments.push(index);

  }
  
  function addSubCommment(uint commentIndex, bytes32 myTextHash, int32 myBegIndex, uint32 myEndIndex) public {
    require(myTextHash.length != 0);
    if(myBegIndex != -1) {
      require(uint(myBegIndex) < myEndIndex);
    }

    require(commentIndex < comments.length);

    uint256 index = subComments.length;
    subComments.push(SubComment({
        textHash: myTextHash,
        begIndex: myBegIndex,
        endIndex: myEndIndex
      }));
    comments[commentIndex].parts.push(index);

  }

  //Returns -1 if author does not exist
  function getAuthorIndexFromName(string name) public constant returns (int) {
    for(uint i = 0; i < authors.length; i++) {
      if(keccak256(authors[i]) == keccak256(name)) {
        return int(i);
      }
    }
    return -1;
  }

  function getAuthorNameFromIndex(uint ind) public constant returns (string) {
    require(ind < authors.length);
    return authors[ind];
  }

  function authorExists(string name) public constant returns (bool) {
    for(uint i = 0; i < authors.length; i++) {
      if(keccak256(authors[i]) == keccak256(name)) {
        return true;
      }
    }
    return false;
  }

  //Returns -1 if article does not exist
  //Gets next article index given possible hash colision
  function getNextArticleIndex(uint start, bytes32 uriHash) public constant returns (int) {
    if(start >= articles.length) {
      return -1;
    }
    for(uint i = start; i < articles.length; i++) {
      if(articles[i].uriHash == uriHash) {
        return int(i);
      }
    }
    return -1;
  }

  function articleExists(bytes32 uriHash, int32 timestamp) public constant returns (bool) {
    for(uint i = 0; i < articles.length; i++) {
      if(articles[i].uriHash == uriHash && articles[i].timestamp == timestamp) {
        return true;
      }
    }
    return false;
  }

  function getContractOwner() public constant returns (address) {
    return contractOwner;
  }

  function getAuthorsLength() public constant returns (uint256) {
    return authors.length;
  }

  function getAuthor(uint256 index) public constant returns (string) {
    return authors[index];
  }

  function getArticlesLength() public constant returns (uint256) {
    return articles.length;
  }
  function getArticle(uint256 index) public constant returns (address, bytes32, int32, bytes32, bytes32, bytes32, bool, uint, uint256[]) {
    Article storage article = articles[index];
    return (article.creatorDomain, article.creator, article.timestamp, article.uriHash, article.titleHash, 
      article.authorHash, article.authorMapped, article.authorIndex, article.comments);
  }

  function getCommentsLength() public constant returns (uint256) {
    return comments.length;
  }
  function getComment(uint256 index) public constant returns (address, bytes32, bytes32, int64, uint32, uint256[]) {
    Comment storage comment = comments[index];
    return (comment.authorDomain, comment.authorId, comment.textHash, comment.begIndex, comment.endIndex, comment.parts);
  }

  function getSubCommentsLength() public constant returns (uint256) {
    return subComments.length;
  }
  function getSubComment(uint256 index) public constant returns (bytes32, int64, uint256) {
    SubComment storage subComment = subComments[index];
    return (subComment.textHash, subComment.begIndex, subComment.endIndex);
  }
}
