# AutoConf tools for Premake

### Get started

```lua
    autoconfigure {
        ['config.h'] = function (cfg)
            check_include(cfg, 'HAVE_STDIO_H', 'stdio.h')
            check_include(cfg, 'HAVE_FOOBAR_H', 'foobar.h')

            check_type_size(cfg, 'SIZEOF_SIZE_T', 'size_t')
        end
    }
```

### Contribute

Awesome! View the [contribution guidelines](https://github.com/premake/premake-core/wiki/Contribution-Guidelines) before you contribute. If you would like to contribute with a new feature or submit a bugfix, fork this repo and send a pull request. Please, make sure all the unit tests are passing before submitting and add new ones in case you introduced new features.

### Copyright & License

Copyright &copy; 2002-2016 by Blizzard Entertainment
Distributed under the terms of the BSD License, see LICENSE.txt



