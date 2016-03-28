import os
import re
import tempfile
import platform
import subprocess

class ExtList (list):

    def findex(self, fun):
        for i, x in enumerate(self):
            if fun(x):
                return i
        raise LookupError('No matching element in list')
    # end def findex
# end class ExtList

def setup_crashkernel_params(pdist, pdistversion):
    if pdistversion == '14.04':
        if os.path.exists('/etc/default/grub.d/kexec-tools.cfg'):
            subprocess.call(r"sed -i 's/crashkernel=.*\([ | \"]\)/crashkernel=384M-2G:64M,2G-16G:128M,16G-:256M\1/g' /etc/default/grub.d/kexec-tools.cfg", shell=True)
        if os.path.exists('/etc/default/kdump-tools'):
            subprocess.call("sed -i 's/USE_KDUMP=0/USE_KDUMP=1/' /etc/default/kdump-tools", shell=True)
    else:
        subprocess.call(r"sed -i 's/crashkernel=.*\([ | \"]\)/crashkernel=384M-2G:64M,2G-16G:128M,16G-:256M\1/g' /etc/grub.d/10_linux", shell=True)
    subprocess.call("update-grub", shell=True)

def enable_kernel_core():
    '''
        enable_kernel_core:
            update grub file
            install grub2
            enable services
    '''
    gcnf = ''
    _temp_dir_name = tempfile.mkdtemp()
    with open('/etc/default/grub', 'r') as f:
        gcnf = f.read()
        p = re.compile('\s*GRUB_CMDLINE_LINUX')
        el = ExtList(gcnf.split('\n'))
        try:
            i = el.findex(p.match)
            exec (el[i])
            el[i] = 'GRUB_CMDLINE_LINUX="%s crashkernel=128M"' % (
                    ' '.join(filter(lambda x: not x.startswith(
                                    'crashkernel='),
                                    GRUB_CMDLINE_LINUX.split())))
            exec (el[i])
            el[i] = 'GRUB_CMDLINE_LINUX="%s kvm-intel.nested=1"' % (
                    ' '.join(filter(lambda x: not x.startswith(
                                    'kvm-intel.nested='),
                                    GRUB_CMDLINE_LINUX.split())))

            with open('%s/grub' % _temp_dir_name, 'w') as f:
                f.write('\n'.join(el))
                f.flush()
            cmd = 'mv %s/grub /etc/default/grub' % (_temp_dir_name)
            subprocess.call(cmd, shell=True)
            subprocess.call('/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg', shell=True)
        except LookupError:
            print 'Improper grub file, kernel crash not enabled'
# end enable_kernel_core

if __name__ == "__main__":
    import cgitb
    cgitb.enable(format='text')
    (pdist, pdistversion, pdistrelease) = platform.dist()
    if pdist in ['fedora', 'centos', 'redhat']:
        enable_kernel_core()
    if pdist == 'Ubuntu':
        setup_crashkernel_params(pdist, pdistversion)
        
