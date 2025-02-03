/* Users */
DROP PROCEDURE IF EXISTS HandleRequest;
DROP PROCEDURE IF EXISTS ParseSearchQuery;
DROP PROCEDURE IF EXISTS AuthUser;
DROP PROCEDURE IF EXISTS HandlerLogin;
DROP PROCEDURE IF EXISTS HandlerRegister;
DROP PROCEDURE IF EXISTS EditPost;
DROP PROCEDURE IF EXISTS PrepareRender;
DROP FUNCTION IF EXISTS RenderHead;
DROP FUNCTION IF EXISTS RenderFooter;
DROP FUNCTION IF EXISTS RenderHeader;
DROP FUNCTION IF EXISTS RenderHTML;
DROP PROCEDURE IF EXISTS RenderHead;
DROP FUNCTION IF EXISTS FORMAT_HTML;
DROP PROCEDURE IF EXISTS DeletePost;
DROP PROCEDURE IF EXISTS GetToken;
DROP PROCEDURE IF EXISTS GetTokenOrNull;
DROP PROCEDURE IF EXISTS GetPost;
DROP PROCEDURE IF EXISTS LikePost;
DROP PROCEDURE IF EXISTS DislikePost;
DROP PROCEDURE IF EXISTS CreatePost;
DROP TABLE IF EXISTS PostsLikes;
DROP TABLE IF EXISTS Posts;
DROP TABLE IF EXISTS Sessions;
DROP TABLE IF EXISTS RegisteredUsers;
DROP TABLE IF EXISTS HtmlTemplates;
DROP EVENT IF EXISTS ClearSessions;

create table HtmlTemplates
(
    Path  varchar(255) not null primary key,
    Value text         not null
);

INSERT INTO HtmlTemplates (Path, Value)
VALUES ('/', '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Social Network</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
        .page { display: none; }
        .active { display: block; }
        .post { border: 1px solid #ddd; padding: 10px; margin: 10px 0; }
        .nav { margin-bottom: 20px; }
        .error { color: red; }
        .success { color: green; }
        form { max-width: 400px; margin: 20px 0; }
        input { display: block; margin: 10px 0; width: 100%; }
        button { margin: 5px; }
    </style>
</head>
<body>
    <div class="nav">
        <a href="#/posts">All Posts</a>
        <span id="authLinks">
            <a href="#/login">Login</a> | <a href="#/register">Register</a>
        </span>
    </div>

    <!-- Login Page -->
    <div id="loginPage" class="page">
        <h2>Login</h2>
        <form id="loginForm">
            <input type="text" placeholder="Login" name="login" required>
            <input type="password" placeholder="Password" name="password" required>
            <button type="submit">Login</button>
        </form>
        <div class="message"></div>
    </div>

    <!-- Registration Page -->
    <div id="registerPage" class="page">
        <h2>Register</h2>
        <form id="registerForm">
            <input type="text" placeholder="Nickname" name="nickname" required>
            <input type="email" placeholder="Email" name="email" required>
            <input type="password" placeholder="Password" name="password" required>
            <button type="submit">Register</button>
        </form>
        <div class="message"></div>
    </div>

    <!-- Posts Page -->
    <div id="postsPage" class="page">
        <h2>All Posts</h2>
        <button onclick="location.hash=''#/create-post''">Create New Post</button>
        <div id="postsList"></div>
    </div>

    <!-- User Profile Page -->
    <div id="profilePage" class="page">
        <h2>User Profile</h2>
        <div id="userPosts"></div>
    </div>

    <!-- Create Post Page -->
    <div id="createPostPage" class="page">
        <h2>Create New Post</h2>
        <form id="createPostForm">
            <input type="text" placeholder="Title" name="title" required>
            <textarea placeholder="Content" name="content" required></textarea>
            <button type="submit">Create Post</button>
        </form>
    </div>

<script>
const API_BASE = ''/'';
let currentUser = JSON.parse(localStorage.getItem(''currentUser''));

// Routing
function handleRoute() {
    const hash = window.location.hash.substring(2);
    const [path, param] = hash.split(''/'');

    document.querySelectorAll(''.page'').forEach(page => page.classList.remove(''active''));

    switch(path) {
        case ''login'':
            showPage(''loginPage'');
            break;
        case ''register'':
            showPage(''registerPage'');
            break;
        case ''posts'':
            showPage(''postsPage'');
            loadPosts();
            break;
        case ''users'':
            showPage(''profilePage'');
            loadUserPosts(param.substring(2));
            break;
        case ''create-post'':
            showPage(''createPostPage'');
            break;
        default:
            showPage(''postsPage'');
            loadPosts();
    }
}

function showPage(pageId) {
    document.getElementById(pageId).classList.add(''active'');
}

// API Handler
async function callAPI(endpoint, params = {}) {
    const url = new URL(API_BASE + endpoint, window.location.origin);
    Object.keys(params).forEach(key => url.searchParams.append(key, params[key]));

    try {
        const response = await fetch(url);
        return await response.json();
    } catch (error) {
        return { error: error.message };
    }
}

// Auth Functions
async function handleLogin(login, password) {
    const response = await callAPI(''login'', { login, password });
    if (response.token) {
        localStorage.setItem(''currentUser'', JSON.stringify(response));
        currentUser = response;
        window.location.hash = ''#/posts'';
    }
    return response;
}

async function handleRegister(nickname, email, password) {
    return await callAPI(''register'', { nickname, email, password });
}

// Post Functions
async function createPost(title, content) {
    return await callAPI(''create-post'', {
        token: currentUser?.token,
        title,
        content
    });
}

async function loadPosts() {
    const posts = await callAPI(''get-post'');
    renderPosts(posts, ''#postsList'');
}

async function loadUserPosts(userId) {
    const posts = await callAPI(''get-post'', { user_id: userId });
    renderPosts(posts, ''#userPosts'');
}

function renderPosts(posts, container) {
    const html = posts?.map(post => `
        <div class="post">
            <h3>${post.title}</h3>
            <p>${post.content}</p>
            <small>By User ${post.user_id} • ${post.likes} likes</small>
            <div>
                <button onclick="likePost(${post.id})">Like</button>
                <button onclick="dislikePost(${post.id})">Dislike</button>
                ${post.user_id === currentUser?.id ? `
                    <button onclick="deletePost(${post.id})">Delete</button>
                ` : ''''}
            </div>
        </div>
    `).join('''');
    document.querySelector(container).innerHTML = html || ''No posts found'';
}

async function likePost(postId) {
    await callAPI(''like-post'', {
        token: currentUser?.token,
        post_id: postId
    });
    loadPosts();
}

async function dislikePost(postId) {
    await callAPI(''dislike-post'', {
        token: currentUser?.token,
        post_id: postId
    });
    loadPosts();
}

async function deletePost(postId) {
    await callAPI(''delete-post'', {
        token: currentUser?.token,
        post_id: postId
    });
    loadPosts();
}

// Event Listeners
window.addEventListener(''hashchange'', handleRoute);
document.addEventListener(''DOMContentLoaded'', handleRoute);

document.getElementById(''loginForm'').addEventListener(''submit'', async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const response = await handleLogin(formData.get(''login''), formData.get(''password''));
    showMessage(e.target.closest(''.page'').querySelector(''.message''), response);
});

document.getElementById(''registerForm'').addEventListener(''submit'', async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const response = await handleRegister(
        formData.get(''nickname''),
        formData.get(''email''),
        formData.get(''password'')
    );
    showMessage(e.target.closest(''.page'').querySelector(''.message''), response);
});

document.getElementById(''createPostForm'').addEventListener(''submit'', async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const response = await createPost(formData.get(''title''), formData.get(''content''));
    if (response.id) {
        window.location.hash = ''#/posts'';
    }
});

function showMessage(element, response) {
    element.className = response.error ? ''error'' : ''success'';
    element.textContent = response.error || response.message || ''Success!'';
}

// Initialization
if (currentUser) {
    document.getElementById(''authLinks'').innerHTML = `
        <span>Welcome ${currentUser.nickname}</span>
        <button onclick="localStorage.removeItem(''currentUser''); location.reload()">Logout</button>
    `;
}
</script>
</body>
</html>');

create table RegisteredUsers
(
    id       int unsigned auto_increment primary key,
    nickname varchar(255) not null unique,
    email    varchar(255) not null unique,
    password char(255)    not null,
    avatar   varchar(255) not null default 'https://i.imgur.com/fXCUcNJ.jpeg'
);
/*Sessions*/
create table Sessions
(
    id         int auto_increment primary key,
    user_id    int unsigned not null,
    session_id char(255)    not null unique,
    expires    datetime     not null
);
CREATE INDEX IDX_SESSION
    ON Sessions (user_id);
ALTER TABLE Sessions
    ADD CONSTRAINT fk_user_id
        FOREIGN KEY (user_id) REFERENCES RegisteredUsers (id) ON DELETE CASCADE;
/*create procedure to auth user by login and password(it would return session_id)*/
create
    definer = root@`%` procedure AuthUser(IN login varchar(255), IN passwordV char(255), OUT session_id_o char(255))
BEGIN
    DECLARE user_id INT;
    DECLARE inser_id INT;
    SELECT id
    INTO user_id
    FROM RegisteredUsers
    WHERE (nickname = login OR email = login)
      AND password = SHA2(CONCAT(passwordV, 'super-duper-salt-123'), 256);
    IF user_id IS NOT NULL THEN
        INSERT INTO Sessions (user_id, session_id, expires)
        VALUES (user_id, SHA2(CONCAT(UUID(), RAND(), RANDOM_BYTES(32)), 256), DATE_ADD(NOW(), INTERVAL 1 DAY));
        SET inser_id = LAST_INSERT_ID();
        SELECT session_id
        INTO session_id_o
        FROM Sessions
        WHERE id = inser_id;
    ELSE
        SIGNAL SQLSTATE '45423' SET MESSAGE_TEXT = 'Invalid login or password';
    END IF;

END;
/*delete session when expire through trigger*/
create definer = root@localhost event ClearSessions on schedule
    every '1' HOUR
    enable
    comment 'Clear sessions'
    do DELETE
       FROM Sessions
       WHERE expires < NOW();


/*posts*/
CREATE TABLE Posts
(
    id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    title   VARCHAR(255) NOT NULL,
    content TEXT         NOT NULL,
    created DATETIME     NOT NULL
);
ALTER TABLE Posts
    ADD CONSTRAINT post_user_id
        FOREIGN KEY (user_id) REFERENCES RegisteredUsers (id) ON DELETE CASCADE;

CREATE TABLE PostsLikes
(
    post_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    date    DATETIME     NOT NULL,
    PRIMARY KEY (post_id, user_id)
);
ALTER TABLE PostsLikes
    ADD CONSTRAINT post_id
        FOREIGN KEY (post_id) REFERENCES Posts (id) ON DELETE CASCADE;
ALTER TABLE PostsLikes
    ADD CONSTRAINT user_id
        FOREIGN KEY (user_id) REFERENCES RegisteredUsers (id) ON DELETE CASCADE;

CREATE
    definer = root@`%` procedure CreatePost()
BEGIN
    DECLARE user_id INT UNSIGNED;
    DECLARE title VARCHAR(255);
    DECLARE content TEXT;
    CALL GetToken(user_id);
    SELECT Value FROM SearchParams WHERE Name = 'title' INTO title;
    SELECT Value FROM SearchParams WHERE Name = 'content' INTO content;
    INSERT INTO Posts (user_id, title, content, created) VALUES (user_id, title, content, NOW());
    SELECT JSON_OBJECT('post_id', LAST_INSERT_ID()) as Post;
END;
create
    definer = root@`%` procedure GetPost()
BEGIN
    DECLARE PostID INT UNSIGNED;
    DECLARE UserId INT UNSIGNED;
    DECLARE Offset INT UNSIGNED DEFAULT 0;
    DECLARE LimitI INT UNSIGNED DEFAULT 10;

    SELECT Value FROM SearchParams WHERE Name = 'post_id' INTO PostID;
    SELECT Value FROM SearchParams WHERE Name = 'offset' INTO Offset;
    SELECT Value FROM SearchParams WHERE Name = 'limit' INTO LimitI;
    SELECT Value FROM SearchParams WHERE Name = 'user_id' INTO UserId;

    SELECT JSON_ARRAYAGG(JSON_OBJECT(
            'content', content,
            'title', title,
            'post_id', id,
            'user', (SELECT JSON_OBJECT(
                                    'nickname', nickname,
                                    'email', email,
                                    'id', r.id
                            )
                     FROM RegisteredUsers r
                     WHERE r.id = user_id),
            'likes', JSON_OBJECT(
                    'count',
                    (SELECT COUNT(*) FROM PostsLikes WHERE post_id = id),
                    'is_like',
                    IFNULL((SELECT 1
                            FROM PostsLikes l
                            WHERE l.post_id = id
                              AND l.user_id = (SELECT user_id
                                               FROM Sessions
                                               WHERE session_id = (SELECT Value FROM SearchParams WHERE Name = 'token'))),
                           0)
                     )
                         )
           ) as Posts
    FROM Posts
    WHERE IF(UserId != 0, user_id = UserId, TRUE)
      AND IF(PostID IS NOT NULL, id = PostID, TRUE)
    ORDER BY created DESC
    LIMIT LimitI OFFSET Offset;
END;
create
    definer = root@`%` procedure EditPost()
BEGIN
    DECLARE PostID INT UNSIGNED;
    DECLARE UserId INT UNSIGNED;
    DECLARE PostRealUserId INT UNSIGNED;
    DECLARE titlet VARCHAR(255);
    DECLARE contentt TEXT;
    SELECT Value FROM SearchParams WHERE Name = 'post_id' INTO PostID;
    SELECT Value FROM SearchParams WHERE Name = 'title' INTO titlet;
    SELECT Value FROM SearchParams WHERE Name = 'content' INTO contentt;
    CALL GetToken(UserId);
    SELECT user_id FROM Posts WHERE id = PostID INTO PostRealUserId;
    IF PostRealUserId = UserId THEN
        UPDATE Posts SET title = titlet, content = contentt WHERE id = PostID;
        SELECT JSON_OBJECT('post_id', PostID) as Post;
    ELSE
        SIGNAL SQLSTATE '45423' SET MESSAGE_TEXT = 'You can not edit this post';
    END IF;
END;
create
    definer = root@`%` procedure DeletePost()
BEGIN
    DECLARE PostID INT UNSIGNED;
    DECLARE UserId INT UNSIGNED;
    DECLARE PostRealUserId INT UNSIGNED;
    SELECT Value FROM SearchParams WHERE Name = 'post_id' INTO PostID;
    CALL GetToken(UserId);
    SELECT user_id FROM Posts WHERE id = PostID INTO PostRealUserId;
    IF PostRealUserId = UserId THEN
        DELETE FROM Posts WHERE id = PostID;
        SELECT JSON_OBJECT('post_id', PostID) as Post;
    ELSE
        SIGNAL SQLSTATE '45423' SET MESSAGE_TEXT = 'You can not delete this post';
    END IF;
END;

/*post like/dislike*/
create
    definer = root@`%` procedure LikePost()
BEGIN
    DECLARE userid INT UNSIGNED;
    DECLARE postid INT UNSIGNED;
    CALL GetToken(userid);
    SELECT Value FROM SearchParams WHERE Name = 'post_id' INTO postid;
    INSERT IGNORE INTO PostsLikes (post_id, user_id, date) VALUES (postid, userid, NOW());
    SELECT JSON_OBJECT('likes', (SELECT COUNT(*)
                                 from `PostsLikes`
                                 WHERE post_id = postid)) as Post;
END;
create
    definer = root@`%` procedure DislikePost()
BEGIN
    DECLARE userid INT UNSIGNED;
    DECLARE postid INT UNSIGNED;
    CALL GetToken(userid);
    SELECT Value FROM SearchParams WHERE Name = 'post_id' INTO postid;
    DELETE FROM PostsLikes WHERE post_id = postid AND user_id = userid;
    SELECT JSON_OBJECT('likes', (SELECT COUNT(*)
                                 from `PostsLikes`
                                 WHERE post_id = postid)) as Post;
END;


/*system*/
create
    definer = root@`%` procedure ParseSearchQuery(IN search_query text)
BEGIN
    DECLARE pair_delimiter VARCHAR(1) DEFAULT '&';
    DECLARE kv_delimiter VARCHAR(1) DEFAULT '=';
    DECLARE current_pair TEXT;
    DECLARE remaining_pairs TEXT DEFAULT search_query;
    DECLARE delimiter_pos INT;

    -- Create temporary table to store results
    DROP TEMPORARY TABLE IF EXISTS SearchParams;
    CREATE TEMPORARY TABLE SearchParams
    (
        Name  VARCHAR(255),
        Value VARCHAR(255)
    );

    -- Loop through all key-value pairs
    WHILE LENGTH(remaining_pairs) > 0
        DO
            -- Find the position of the next pair delimiter
            SET delimiter_pos = LOCATE(pair_delimiter, remaining_pairs);

            -- Extract the current key-value pair
            IF delimiter_pos = 0 THEN
                SET current_pair = remaining_pairs;
                SET remaining_pairs = '';
            ELSE
                SET current_pair = SUBSTRING(remaining_pairs, 1, delimiter_pos - 1);
                SET remaining_pairs = SUBSTRING(remaining_pairs, delimiter_pos + 1);
            END IF;

            -- Split the key and value
            SET delimiter_pos = LOCATE(kv_delimiter, current_pair);
            IF delimiter_pos > 0 THEN
                INSERT INTO SearchParams (Name, Value)
                VALUES (TRIM(SUBSTRING(current_pair, 1, delimiter_pos - 1)),
                        TRIM(SUBSTRING(current_pair, delimiter_pos + 1)));
            END IF;
        END WHILE;
END;

/*login/register */
/*handling request*/
create
    definer = root@`%` procedure HandlerLogin()
BEGIN
    DECLARE SessionId TEXT;
    DECLARE Login VARCHAR(255);
    DECLARE Password CHAR(255);
    SELECt Value FROM SearchParams WHERE Name = 'login' INTO Login;
    SELECt Value FROM SearchParams WHERE Name = 'password' INTO Password;
    CALL AuthUser(Login, Password, SessionId);
    SELECT JSON_OBJECT('token', SessionId) as Token;
END;
create
    definer = root@`%` procedure HandlerRegister()
BEGIN
    DECLARE Nickname VARCHAR(255);
    DECLARE Email VARCHAR(255);
    DECLARE PasswordV TEXT;
    DECLARE SessionID CHAR(255);
    SELECT Value FROM SearchParams WHERE Name = 'nickname' INTO Nickname;
    SELECT Value FROM SearchParams WHERE Name = 'email' INTO Email;
    SELECT Value FROM SearchParams WHERE Name = 'password' INTO PasswordV;
    INSERT INTO RegisteredUsers (nickname, email, password)
    VALUES (Nickname, Email, SHA2(CONCAT(PasswordV, 'super-duper-salt-123'), 256));

    CALL AuthUser(Nickname, PasswordV, SessionID);

END;
create
    definer = root@`%` procedure GetToken(OUT out_user INT UNSIGNED)
BEGIN
    DECLARE UserLocal INT UNSIGNED DEFAULT 0;
    DECLARE token CHAR(255);
    SELECT Value FROM SearchParams WHERE Name = 'token' INTO token;
    SELECT user_id from Sessions WHERE session_id = token INTO UserLocal;
    IF UserLocal = 0 THEN
        SIGNAL SQLSTATE '45423' SET MESSAGE_TEXT = 'Invalid token';
    ELSE
        SET out_user = UserLocal;
    END IF;
END;
create
    definer = root@`%` procedure GetTokenOrNull(OUT out_user INT UNSIGNED)
BEGIN
    DECLARE token CHAR(255);
    SELECT Value FROM SearchParams WHERE Name = 'token' INTO token;
    SELECT user_id from Sessions WHERE session_id = token INTO out_user;

END;

/*global */
create
    definer = root@`%` procedure HandleRequest(IN uri text)
BEGIN
    /*split query by ?*/
    DECLARE query TEXT;
    DECLARE path TEXT;
    DECLARE delimiter_pos INT;
    SET delimiter_pos = LOCATE('?', uri);
    IF delimiter_pos = 0 THEN
        SET path = uri;
        SET query = '';
    ELSE
        SET path = SUBSTRING(uri, 1, delimiter_pos - 1);
        SET query = SUBSTRING(uri, delimiter_pos + 1);
    END IF;
    CALL ParseSearchQuery(query);

    IF path = '/' THEN
        SELECT Value FROM HtmlTemplates WHERE Path = '/';
    ELSEIF path = '/login' THEN
        Call HandlerLogin();
    ELSEIF path = '/register' THEN
        CALL HandlerRegister();
    ELSEIF path = '/create-post' THEN
        CALL CreatePost();
    ELSEIF path = '/get-post' THEN
        CALL GetPost();
    ELSEIF path = '/edit-post' THEN
        CALL EditPost();
    ELSEIF path = '/delete-post' THEN
        CALL DeletePost();
    ELSEIF path = '/like-post' THEN
        CALL LikePost();
    ELSEIF path = '/dislike-post' THEN
        CALL DislikePost();
    ELSE
        SELECT JSON_OBJECT('error', 'unknown method called') as Error;
    end if;

END;




CALL HandleRequest('/register?nickname=John&email=john.bob@gmail.com&password=hello');
CALL HandleRequest('/register?nickname=Bob&email=bob@gmail.com&password=bob');
CALL HandleRequest('/login?login=John&password=hello');
CALL HandleRequest('/login?login=Bob&password=bob');
-- select into token value from Sessions;
SELECT session_id
FROM Sessions
LIMIT 1
INTO @token;
SELECT session_id
FROM Sessions
LIMIT 1 OFFSET 1
INTO @token2;
CALL HandleRequest(concat('/create-post?token=', @token, '&title=Hello&content=World'));
CALL HandleRequest(concat('/create-post?token=', @token2, '&title=Hello from bob&content=World from bob'));
CALL HandleRequest(concat('/create-post?token=', @token2, '&title=Hello from bob 2&content=World from bob 2'));
CALL HandleRequest('/get-post?post_id=1');
CALL HandleRequest('/get-post?post_id=2');
CALL HandleRequest('/get-post?user_id=2');
CALL HandleRequest(CONCAT('/delete-post?post_id=1&token=', @token));
CALL HandleRequest('/get-post?post_id=1');
CALL HandleRequest(CONCAT('/like-post?post_id=2&token=', @token));
CALL HandleRequest(CONCAT('/like-post?post_id=2&token=', @token2));
CALL HandleRequest(CONCAT('/dislike-post?post_id=2&token=', @token));
CALL HandleRequest(CONCAT('/get-post?post_id=2&token=', @token2));
CALL HandleRequest(CONCAT('/edit-post?post_id=2&token=', @token2, '&title=New title&content=New description'));
CALL HandleRequest('/get-post?post_id=2');
CALL HandleRequest(CONCAT('/?token=', @token2));