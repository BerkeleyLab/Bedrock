RTL Coding Guidelines
=====================

The following is a set of RTL coding guidelines with the purpose of maximizing the readability and maintainability
of the codebase, without being too restrictive or inconvenient. The goal is to achieve a consistent 'look and feel'
across the several modules and subsystems, so long-term and new contributors alike can infer some of the
module's functionality and, more importantly, its interface, without having to reverse-engineer the code. This will
hopefully promote contributions, facilitate code re-use and mitigate fragmentation.

These guidelines should be general enough such that they are not restricted to a specific Hardware Description Language, unless otherwise noted.

Each guideline is individually labeled so it can be easily referred to in the context of code reviews or issue creation.

A - Interfaces
--

#### A.1 - Interface signal naming
In the context of RTL modules, an interface is a collection of input/output signals that, when used together, implement a protocol that allows for the transfer of data in one, or both, directions. These closely-related signals should, therefore, share a common prefix that makes their relationship clear. This becomes even more important when the interface is associated with a specific clock domain. E.g.: lb_clk, lb_valid, lb_rnw, lb_wdata, lb_rdata.


#### A.2 - Keeping interfaces standard
In order to promote interface re-use and facilitate module interoperability, custom interfaces and protocols should be avoided whenever possible. Instead, conventional interface design patterns should be preferred, along with the use of traditional naming for both control and data signals. E.g. lb_valid, lb_ready/lb_enable, lb_wdata, lb_wstb/lb_wmask.

Deviations from this recommendation should be accompanied by detailed documentation that goes beyond what is usually expected.

B - Signal naming
--

#### B.1 - Registered and Delayed signals
Registered or delayed versions of a signal should use the suffix '_r' or '_d'. Where multiple delays are required,
a number should be appended to the suffix. E.g.: valid_r, valid_r2, valid_r3.

#### B.2 - Internal or Local signals
Internal or local signals that have no other purpose other than to create an internal version of a module's port should
use the port name followed by the suffix '_l' or '_i'.

#### B.3 - Signal case
All signal names should be lower-case and use snake-case, not camel-case. E.g.: valid_out, data_in.

#### B.4 - Active-low signals
Active-low signals should make use of the suffix _n. E.g.: reset_n, ce_n.

C - Module declaration
--

#### C.1 - Parameter naming
Parameters should be in all-caps, snake-case, and sufficiently descriptive so that no additional explanation is required.
Common abbreviations, such as 'DWI' and 'AWI' for 'data width' and 'address width', are acceptable, but anything
more obscure is best avoided.

#### C.2 - Parameter defaults
All parameters shall have reasonable defaults, such that if the module were to be simulated without any of its parameters
being overridden, it would perform its typical functionality.

D - Module instantiation
--

#### D.1 - Instance names
Module instance names should be prefixed by 'i_', include the module name, or an easily recognizable variant of it (in cases where the
full module name is too long), and an optional suffix that clarifies the purpose of the instance or disambiguates between
instances of the same module. E.g.: i_sqrt, i_mixer_field, i_shortfifo_lb.

#### D.2 - Unconnected ports
Unconnected output ports should never be omitted, but rather included in the module instantiation so it is obvious that they
have been intentionally left open. It is recommended that an inline comment is added to justify why the port is unused.

#### D.3 - Port and parameter assignment
All ports and parameters should always be connected by name. Unlike unconnected ports, however, it is reasonable to omit un-used parameters.

E - Misc
--

#### E.1 - TODOs and unfinished code
TODOs and unfinished code are best avoided in checked-in code, but if they must be used they should be clearly marked with a 'TODO' tag. Alternative
tags should be avoided as they may more easily go unnoticed.

#### E.2 - Comments
In addition to being be useful, clear and concise, comments should not include question marks, rhetorical questions or hypotheticals.

#### E.3 - Precedence rules
Non-obvious operator precedence rules should be avoided. Whenever precedences are not completely clear, parentheses should be used.

