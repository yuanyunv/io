#!/usr/bin/python
#****************************************************************#
# Encoding utf8
# ScriptName: io.py
# Create Date: 2014/01/10 13:37
# Modify Date: 2014-01-13 13:37
# Function: 
#***************************************************************#

import os,sys,time,getopt
import datetime
import threading, signal
is_exit = False
class Now_Time_Stamp:
    def __init__( self  ) :
        self.timestamp_now = int(time.time())
    def __del__(self):
        class_name = self.__class__.__name__
    def timestamp(self) :
        return self.timestamp_now
def handler(signum, frame):
    global is_exit
    is_exit = True
    print 'Program io exit'

class colors :
    BLACK='\033[0;30m'
    DARKRED='\033[0;31m'
    DARKBLUE='\033[0;32m'
    DARKYELLOW='\033[0;33m'
    DARKYELLOW='\033[0;34m'
    DARKMAGENTA='\033[0;35m'
    DARKCYAN='\033[0;36m'
    SILVER='\033[0;37m'
    GRAY='\033[1;30m'
    RED='\033[1;31m'
    BLUE='\033[1;32m'
    YELLOW='\033[1;33m'
    YELLOW='\033[1;34m'
    MAGENTA='\033[1;35m'
    CYAN='\033[1;36m'
    WHITE='\033[1;37m'
    BLACKBG='\033[40m'
    REDBG='\033[41m'
    BLUEBG='\033[42m'
    YELLOWBG='\033[43m'
    YELLOWBG='\033[44m'
    MAGENTABG='\033[45m'
    CYANBG='\033[46m'
    WHITEBG='\033[47m'
    RESET='\033[0;0m'
    BOLD='\033[1m'
    REVERSE='\033[2m'
    UNDERLINE='\033[4m'
    CLEAR='\033[2J'
    CLEARLINE='\033[2K'
    SAVE='\0337'
    RESTORE='\0338'
    UP='\033[1A'
    DOWN='\033[1B'
    RIGHT='\033[1C'
    LEFT='\033[1D'
    DEFAULT='\033[0;0m'
    def disable(self):
        self.OKBLUE = ''
        self.OKGREEN = ''
        self.FAIL = ''
def usage() :
    print colors.MAGENTA + '''\
    Program io
    read Cgroup Blkio Group as group['ins'] , ins as '3001','3002'
    display every instance read io , write io , r+w iops and all instance iops\
    Usage : io [OPTIOIN]
    -h print help
    -i --interval=1 interval /s
    -g --group= group as ['3001','3002']
    -m --mount=/cgroup/blkio cgroup blkio mount point , group name as 3001 , 3002
    ''' + colors.RESET
class Fetchio:
    """
    Fetch Specify Instance IOPS Value
    """
    def __init__( self , group , path ) :
        self.group = group
        self.iofile = '/blkio.throttle.io_serviced'
        self.mountdir = path
        self.io_file_path = self.mountdir+self.group + self.iofile
        self.interval = 1
        self.fp = file(self.io_file_path,'rt')
        self.read=0
        self.write=0
        self.readline=""
    def __del__(self):
        class_name = self.__class__.__name__
    def nowiops(self) :
        for line_num in range(1,20) :
            self.readline=self.fp.readline()
            if len(self.readline) < 5 :
                    continue
            if self.readline.split(' ' , 3)[1] == 'Read' :
                self.read = self.readline.split(' ' , 3)[2]
            elif self.readline.split(' ' , 3)[1] == 'Write' :
                self.write = self.readline.split(' ' , 3)[2]
            else :
                continue
        return int(self.read) , int(self.write)
    def closefp(self) :
        self.fp.close()
def returnstr(str,endflag,fill) :
    prtlen=10
    strlen=( prtlen - len( str ) )
    if endflag == 'head' :
        return colors.YELLOW + '|' + fill*2 + colors.RESET + colors.BLUE + str + colors.RESET + colors.YELLOW + fill*strlen + colors.RESET
    else :
        return colors.YELLOW + fill*2 + colors.RESET + colors.BLUE + str + colors.RESET + colors.YELLOW + fill*strlen + '|' + colors.RESET
def processer() :
    printlen=20
    group_value_list={}
    number=1
    try:
        opts,args = getopt.getopt(sys.argv[1:],'h:i:g:m:',['help'])
    except getopt.GetoptError,e:
        print '[Error] ',e,'\n'
        usage()
        sys.exit(1)
    interval=1
    mounts='/cgroup/mycgroup/blkio/'
    group=[]
    groups=[]
    for o,a in opts:
        if o in ( '-i' , '--interval' ) :
            interval = int(a)
        elif o in ('-m' , '--mount' ) :
            mounts = a
        elif o in ('-g' , '--group' ) :
            groups = a
        elif o in ('-h','--help'):
            usage()
            sys.exit(0)
    if len(groups) == 0 :
        group=['3001','3002']
    else :
        group=groups.split(',')
    #if not opts:
    #    usage()
    #    sys.exit(1)
    while not is_exit :
        split_line=1
        now_group_value_list={}
        band=''
        print_str=''
        bond_head=''
        iops=0
        for ins in group :
            times=Now_Time_Stamp()
            fetchios=Fetchio( ins , mounts )
            nowiops=fetchios.nowiops()
            now_group_value_list['%s'%ins]={'Read':nowiops[0],'Write':nowiops[1],'TimeStamp':times.timestamp()}
            fetchios.closefp()
            del times
            del fetchios
        if number==1 :
            group_value_list=now_group_value_list
        else :
            for ins in group :
                timestamp_diff = now_group_value_list['%s' % ins]['TimeStamp'] -  group_value_list['%s' % ins]['TimeStamp']
                rio = ( now_group_value_list['%s' % ins]['Read'] -  group_value_list['%s' % ins]['Read'] ) / timestamp_diff
                wio = ( now_group_value_list['%s' % ins]['Write'] -  group_value_list['%s' % ins]['Write'] ) / timestamp_diff
                rwio=wio + rio
                if split_line == 1 :
                    band=band + returnstr('Instance','head','-')+returnstr('Read','center','-')+returnstr('Write','center','-')+returnstr('rwio','center','-')
                    print_str=print_str+returnstr( ins ,'head',' ')+returnstr( '%d'%rio ,'center',' ')+returnstr( '%d'%wio ,'center',' ')+returnstr('%d'%rwio,'center',' ')
                else :
                    band=band+returnstr('Instance','center','-')+returnstr('Read','center','-')+returnstr('Write','tail','-')+returnstr('rwio','center','-')
                    print_str=print_str+returnstr( ins ,'center',' ')+returnstr( '%d'%rio ,'center',' ')+returnstr( '%d'%wio ,'center',' ')+returnstr('%d'%rwio,'center',' ')
                iops=iops+rwio
                split_line=split_line+1
            print_str=print_str+returnstr('%d'%iops,'center',' ')+returnstr('%s' % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),'center',' ')
        group_value_list=now_group_value_list
        band=band+returnstr( 'iops' ,'center','-') + colors.YELLOW + '-'*8+'Time'+'-'*9+'|' + colors.RESET
        if number == 2 :
#            print ( colors.RED + '-' * 138 + colors.RESET )
            print band
        if ( (number % 40) == 0 ):
            print band
        print(print_str)
        number=number+1
        time.sleep(interval)

def main() :
    signal.signal(signal.SIGINT, handler)
    signal.signal(signal.SIGTERM, handler)
    threads = []
    t = threading.Thread(target=processer, args=())
    t.setDaemon(True)
    threads.append(t)
    t.start()
    while 1:
        alive = False
        alive = alive or threads[0].isAlive()
        if not alive :
            break

if __name__ == '__main__' :
    '''
    Inbond
    '''
    print colors.MAGENTA + '''\
        Program io
        read Cgroup Blkio Group as group['ins'] , ins as '3001','3002'
        display every instance read io , write io , r+w iops and all instance iops
    '''
    main()
