---
title: "Exploring Pytest Fixtures: Notes and Examples"
page_title: "Exploring Pytest Fixtures: Notes and Examples"
excerpt: "Here, I present a compilation of notes and practical scenarios 
drawn from my experiences, demonstrating the effective utilization of pytest 
fixtures. These examples provide valuable insights into leveraging fixtures 
to refine and improve the architecture of your testing module."
date: October 31, 2023
toc: true
toc_label: "Content"
toc_sticky: true
last_modified_at: October 31, 2023
og_image: /assets/images/posts/pytest-fixtures-notes-examples/header.jpg
---

{% include image.html
    src="/assets/images/posts/pytest-fixtures-notes-examples/header.jpg"
    alt="pytest-fixtures-notes-examples"
    caption="Image Source: <a href='https://www.pexels.com/' target='_blank'>Pexels</a>"
%}

## Introduction

I've been utilizing pytest for quite some time now, and I find concepts such as 
patching, fixtures, and parametrization quite intuitive. Nonetheless, at one point, 
I started thinking about the architectural aspects of the entire testing module 
and how they influence the actual test code. Improving performance can be 
achieved by scoping fixtures, particularly when dealing with fixtures 
that involve network access. However, this approach raises questions about 
multiple tests accessing the same fixture instance and the teardown process. 
Not to mention complexities that always arise when introducing test 
parallelization, for example using 
[pytest-xdist](https://github.com/pytest-dev/pytest-xdist){:target="_blank"}.

The answers to most of these questions are strongly tied to a specific use case, 
and having a deep understanding of all the ways we can utilize fixtures can 
lead to better architectural decisions.

This post is a collection of notes and examples that I've gathered during my 
research, mainly serving as a reference. The 
[documentation on fixtures](https://docs.pytest.org/en/latest/explanation/fixtures.html){:target="_blank"} 
is very extensive and covers all the details, so be sure to check it out.

If you possess some familiarity with pytest, I hope that this post will inspire 
you to delve further into the specifics and make architectural choices that 
can enhance your project and simplify your work.

## Features

### Autouse

As we are already know, we can request a fixture by specifying it in a 
test's signature. For example:

```python
import pytest


@pytest.fixture
def empty_list():
    return []


def test_empty_list(empty_list):
    assert len(empty_list) == 0
```

The signature of `test_empty_list(empty_list)` requests fixture `empty_list`. 
Of course, we can request as many fixtures as we want by specifying them next 
to each other in the signature.

The `autouse` fixtures are a convenient way to make all tests automatically 
request them without specifying them in the signature explicitly. This 
eliminates unnecessary calls and reduces the clutter in the signature.

To create an `autouse` fixture, just pass the `autouse=True` to the fixture's 
decorator:

```python
import pytest


@pytest.fixture
def value():
    return []


@pytest.fixture(autouse=True)
def empty_list(value):
    return value.append(1)


def test_empty_list(value):
    assert len(value) == 1
```

This is useful when we need to apply a side-effect before and/or after each 
test unconditionally.

### Scope

The scope of a fixture defines the level on which it's being invoked and 
destroyed. Fixtures are created when first requested by a test, and are 
destroyed based on their scope, which can take the following values:

- **function**: the default scope, the fixture is destroyed at the end of the test.
- **class**: the fixture is destroyed during teardown of the last test in the class.
- **module**: the fixture is destroyed during teardown of the last test in the module.
- **package**: the fixture is destroyed during teardown of the last test in the package.
- **session**: the fixture is destroyed at the end of the test session.

This is beneficial for generating resources that typically involve substantial 
time and effort in their creation, such as HTTP servers, Docker containers, 
and so on. In that case we can specify the scope to be `session` and the same 
instance will persist for all tests. Multiple tests will receive the same 
fixture instance, which saves time and increases the performance.

Fixtures have to adhere to the scope hierarchy. This means that a fixture of 
higher scope cannot depend on a fixture of lower scope.

For example, let's say that we create a value on a session level, and then use 
a fixture that modifies it:

```python
import pytest


@pytest.fixture(scope="session")
def value():
    return []


@pytest.fixture(scope="function")
def add(value):
    return value.append(1)


def test_list(value, add):
    assert len(value) == 1
```

This is fine, since `add` is scoped on a function level, while `value` is of 
higher scope. If you switch the scopes, you'll get `ScopeMismatch` stating:

```text
ScopeMismatch: You tried to access the 'function' scoped fixture 'value' 
with a 'session' scoped request object, involved factories
```

### Yield

The `return` from a fixture can be swapped with `yield`, which still allows us 
to run some code and pass an object to requesting fixture or test.

However, the difference is that any code after `yield` will get executed. It's 
important to note that the order in which the yield fixtures are executed is 
linear. In setup it's going top to bottom and in reverse order during teardown. 
Next example illustrates this:

```python
import pytest


@pytest.fixture()
def a():
    print("starting a")
    yield
    print("exiting a")


@pytest.fixture()
def b(a):
    print("starting b")
    yield
    print("exiting b")


def test(b):
    print("executing test...")
```

Executing this with appropriate flags for output gives the following:

```text
starting a
starting b
executing test...
exiting b
exiting a
```

### Setup/Teardown

Having in mind the `autouse`, `scope`, and `yield`, we can construct a fixture 
that will run before or after each or all tests depending on the scope. This can 
be useful in many ways. For example, creating a table, setting up an http 
server before all tests but also cleaning the state before and after each test. 
What's important is that by using the `yield` we can define the teardown 
process in each fixture.

The following code illustrates the process:

```python
import pytest


@pytest.fixture(autouse=True, scope="module")
def a():
    print("Setup before all tests")
    yield
    print("Teardown after all tests")


@pytest.fixture(autouse=True)
def b():
    print("Before each test")
    yield
    print("After each test")


def test_1():
    print("Executing test 1...")


def test_2():
    print("Executing test 2...")
```

Executing this gives:

```text
Setup before all tests
Before each test
Executing test 1...
After each test
Before each test
Executing test 2...
After each test
Teardown after all tests
```

Having the right order of fixtures and teardowns doesn't guarantee a safe 
teardown. The documentation goes into details on this topic, so be sure to 
check 
[Safe teardowns](https://docs.pytest.org/en/latest/how-to/fixtures.html#safe-teardowns){:target="_blank"}. 
In summary, it's advisable not to define extensive setup and teardown 
procedures that include numerous state changes, as a failure in one of these 
steps can disrupt the execution of others. This can lead to complications, 
as when a setup step fails, none of the teardown code will be executed. 
Instead, we should strive to create fixtures in a limited way, 
creating only one state-changing action. Doing so, we are lowering the chances 
of leaving the resources hanging in the case when something fails.

### Inspecting fixtures

Of course, in real life, we could have a lot of fixtures with different scopes 
and complicated orders, therefore a simple `print` won't work. 
Getting the grasp of the fixture setup can be done using the `--setup-only` 
flag, like this:

```bash
pytest --setup-only pytest_test.py::test_1
```

This will give us an idea of what's going on. Using the previous example, we get:

```text
pytest_test.py 
    SETUP    M a
        SETUP    F b
        pytest_test.py::test_1 (fixtures used: a, b)
        TEARDOWN F b
    TEARDOWN M a
```

Besides the `SETUP` and `TEARDOWN`, we can see that `M` and `F` give us the 
information about the scope, `module` and `function` respectively.

If we just want the list of fixtures used for a particular test, we can use the 
`--fixtures-per-test` flag.

The `--fixtures` flag will output all available custom and built-in fixtures 
defined in our testing module.

### Fixture based on arguments

We can create a fixture whose returned value depends on a parameter by 
returning a function that generates the data, rather than returning the data 
directly.

```python
import pytest


@pytest.fixture
def generate_list():
    def _generate_list(*args):
        return list(args)

    return _generate_list


def test_customer_records(generate_list):
    list_1 = generate_list(1, 2, 3)
    list_2 = generate_list("a", "b", "c")
    print(list_1)
    print(list_2)
```

The output:

```text
[1, 2, 3]
['a', 'b', 'c']
```

The fixture is instantiated when it's first requested by the test. However, in 
this case, it returns a function which allows us to have a dynamic behavior 
based on input arguments.

Combining this approach with the use of `yield`, we have the capability to 
define a dynamic fixture that generates return values based on arguments while 
also retaining them for future teardown.

```python
import pytest


@pytest.fixture
def generate_list():
    generated_lists = []

    def _generate_list(*args):
        result = list(args)
        generated_lists.append(result)
        return result

    yield _generate_list

    print(generated_lists)


def test_customer_records(generate_list):
    list_1 = generate_list(1, 2, 3)
    list_2 = generate_list("a", "b", "c")
    print(list_1)
    print(list_2)
```

which gives:

```text
[1, 2, 3]
['a', 'b', 'c']
[[1, 2, 3], ['a', 'b', 'c']]
```

## Design

When we are designing a testing module, we should think about the definition 
and availability of fixtures. Questions like:
- What should be the scope of this fixture?
- Do I need to teardown something?
- When do I need to set it up and tear it down?
- Should it be dynamic based on the arguments?

should be answered before we start building up the architecture of fixtures.

The file structure holds significance, and a particular file named 
`conftest.py` fulfills a unique purpose. Fixtures defined within the 
`conftest.py` can be accessed by any test within the same package without 
requiring explicit imports.

Moreover, we can have a nested directories/packages containing tests and each 
directory can have a separate `conftest.py` with its own fixtures. Note that 
child `conftest.py` also extends parent. This allows us to build a clear and 
concise fixture structure.

Let's imagine that we have the following file structure:

```text
tests/
    conftest.py -> fixture: top
    service_a/
        conftest.py -> fixture: fixture_service_a
        test_service_a_1.py -> fixture: fixture_a_1
        test_service_a_2.py -> fixture: fixture_a_2
    service_b/
        conftest.py -> fixture: fixture_service_b
        test_service_b_1.py -> fixture: fixture_b_1
        test_service_b_2.py -> fixture: fixture_b_2
```

The following diagram could be used to illustrate this structure:

{% include image.html
    src="/assets/images/posts/pytest-fixtures-notes-examples/pytest_diagram.png"
    alt="pytest-structure-diagram"
    caption="Depiction of fixtures' file structure"
%}

Note that we are talking about fixture availability and file structure, this 
has nothing to do with order which is defined using `scope` and hierarchy.

Let's look at some examples, it'll provide greater clarity.

## Examples

### Docker

If we are building a service that interacts with an SFTP server and/or a 
database, for example. We can run a docker container in the background and 
simulate the interaction. This allows us to have the proper testing structure 
of defining the state, action, and asserting the result.

Running a Docker container and configuring its state for each individual test 
can consume a significant amount of time. Thus, it is crucial to effectively 
manage a fixture with the appropriate scope.

We want to dynamically get an unused port that will be used for interacting 
with the service inside docker. This could be achieved with the following 
fixture:

```python
import time
import socket
import pytest
import docker


@pytest.fixture(scope="session")
def unused_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("localhost", 0))
        return sock.getsockname()[1]
```

This fixture is then used to run a docker container in another fixture:

```python
@pytest.fixture(scope="session")
def run_docker(unused_port):
    client = docker.from_env()
    container = client.containers.run(
        image="<image>",
        auto_remove=True,
        name="<container-name>",
        ports={"<port>": unused_port},
        detach=True,
        remove=True,
        command="<command>",
    )

    time.sleep(5)

    yield

    container.stop()
```

Here, we are using `time.sleep(5)` to wait for a docker container to star. 
However, in some real-life scenario, you would define some kind of check to 
confirm that the instance is up and running, for example by making backoff 
API calls as health checks.

The key point to emphasize is that we are executing a Docker container instance 
within the `session` scope using `yield`, and subsequently, we ensure that the 
container is stopped.

### SFTP

Now, let's observe this in practice by employing an SFTP server within a Docker 
container. There's an easy to use SFTP server with OpenSSH as a pre-built docker 
image: [emberstack/sftp](https://hub.docker.com/r/emberstack/sftp){:target="_blank"}. 
To interact with it, let's use 
[paramiko](https://github.com/paramiko/paramiko){:target="_blank"}.

We can run the SFTP server with the following fixture:

```python
@pytest.fixture(scope="session", autouse=True)
def run_docker(unused_port):
    client = docker.from_env()
    container = client.containers.run(
        image="emberstack/sftp",
        auto_remove=True,
        name="sftp",
        ports={"22": unused_port},
        detach=True,
        remove=True,
    )

    time.sleep(5)

    yield unused_port

    container.stop()
```

> Please be aware that the use of `time.sleep(5)` should be enhanced and 
> replaced with a backoff mechanism for SFTP connection initialization. I 
> will just leave it as is for now, as it holds no significance within 
> the scope of this discussion.

Note that we are using `autouse=True`, which means that the `run_docker` fixture 
will create a docker container for the whole testing session and we don't have 
to request it in each test.

Having an SFTP server doesn't mean much if we don't connect to it. The 
connection can also be established by utilizing a `yield` fixture within a 
`with` context manager, providing a more straightforward method for handling 
the connection's closure.

```python
@pytest.fixture(scope="session")
def sftp_client(unused_port):
    with paramiko.Transport(("localhost", unused_port)) as transport:
        transport.connect(username=USERNAME, password=PASSWORD)
        with paramiko.SFTPClient.from_transport(transport) as client:
            yield client
```

Finally, we pass the client fixture to a test:

```python
def test_mkdir(sftp_client):
    assert len(sftp_client.listdir()) == 0
    sftp_client.mkdir("example")
    assert sftp_client.listdir() == ["example"]
```

The `sftp_client.mkdir()` can be designated as an independent fixture 
that generates directories according to the provided input parameter and
maintains a record of them for cleanup. This can be demonstrated as follows:

```python
@pytest.fixture()
def mkdir(sftp_client):
    paths = []

    def _mkdir(name):
        paths.append(name)
        sftp_client.mkdir(name)

    yield _mkdir

    for path in paths:
        sftp_client.rmdir(path)
```

Please take note that the fixture's scope is limited to the function level, 
which implies that the state will be reset between different tests. To 
illustrate this, we can create two analogous tests:

```python
def test_mkdir_1(sftp_client, mkdir):
    assert len(sftp_client.listdir()) == 0
    mkdir("a")
    mkdir("b")
    assert sftp_client.listdir() == ["b", "a"]


def test_mkdir_2(sftp_client, mkdir):
    assert len(sftp_client.listdir()) == 0
    mkdir("c")
    mkdir("d")
    assert sftp_client.listdir() == ["d", "c"]
```

which runs without any errors. The same should be done for other SFTP actions.

Inspecting the order and hierarchy of fixtures using `--setup-only`, we get:

```text
SETUP    S unused_port
SETUP    S run_docker (fixtures used: unused_port)
SETUP    S sftp_client (fixtures used: unused_port)
        SETUP    F mkdir (fixtures used: sftp_client)
        pytest_test.py::test_mkdir_1 (fixtures used: mkdir, run_docker, sftp_client, unused_port)
        TEARDOWN F mkdir
        SETUP    F mkdir (fixtures used: sftp_client)
        pytest_test.py::test_mkdir_2 (fixtures used: mkdir, run_docker, sftp_client, unused_port)
        TEARDOWN F mkdir
TEARDOWN S sftp_client
TEARDOWN S run_docker
TEARDOWN S unused_port
```

With any luck, this provides greater clarity, and I hope it'll inspire you to 
embark on your own journey of exploration and enhance the design of your 
testing module.

## Resources

- [pytest fixtures: explicit, modular, scalable](https://docs.pytest.org/en/latest/explanation/fixtures.html){:target="_blank"}