use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	=> 'RCU::Irman',
    VERSION_FROM=> 'Irman.pm',
    LIBS	=> ['-lirman'],
    DEFINE	=> '',
    INC		=> '',
);
