require 'spec_helper_system'

describe 'fragment should accept source lists' do
  shell('rm /tmp/file')
  file1_contents="file1 contents"
  file2_contents="file2 contents"
  shell("echo '#{file1_contents}' > /tmp/file1")
  shell("echo '#{file2_contents}' > /tmp/file2")
  context 'should create files containing first match only.' do
    pp="
      concat { '/tmp/result_file1':
        owner   => root,
        group   => root,
        mode    => '0644',
        replace => false,
      }
      concat { '/tmp/result_file2':
        owner   => root,
        group   => root,
        mode    => '0644',
        replace => false,
      }
      concat { '/tmp/result_file3':
        owner   => root,
        group   => root,
        mode    => '0644',
        replace => false,
      }

      concat::fragment { '1':
        target  => '/tmp/result_file1',
        source => [ '/tmp/file1', '/tmp/file2' ]
        order   => '01',
      }
      concat::fragment { '2':
        target  => '/tmp/result_file2',
        source => [ '/tmp/file2', '/tmp/file1' ]
        order   => '01',
      }
      concat::fragment { '3':
        target  => '/tmp/result_file3',
        source => [ '/tmp/file1', '/tmp/file2' ]
        order   => '01',
      }
    "
    context puppet_apply(pp) do
      its(:stderr) { should be_empty }
      its(:exit_code) { should_not == 1 }
      its(:refresh) { should be_nil }
      its(:stderr) { should be_empty }
      its(:exit_code) { should be_zero }
    end
    describe file('/tmp/result_file1') do 
      it { should be_file }
      it { should contain file1_contents }
      it { should_not contain file2_contents }
    end
    describe file('/tmp/result_file2') do 
      it { should be_file }
      it { should contain file2_contents }
      it { should_not contain file1_contents }
    end
    describe file('/tmp/result_file3') do 
      it { should be_file }
      it { should contain file1_contents }
      it { should_not contain file2_contents }
    end
  end
  
  shell('rm /tmp/file /tmp/file1 /tmp/file2')
  context 'should fail if no match on source.' do
    pp="
      concat { '/tmp/file':
        owner   => root,
        group   => root,
        mode    => '0644',
      }

      concat::fragment { '1':
        target  => '/tmp/file',
        source => [ '/tmp/file1', '/tmp/file2' ]
        order   => '01',
      }
    "
    context puppet_apply(pp) do
      its(:stderr) { should be_empty }
      its(:exit_code) { should_not == 1 }
      its(:refresh) { should be_nil }
      its(:stderr) { should be_empty }
      its(:exit_code) { should be_zero }
    end
    describe file('/tmp/file') do
       it { should_not exist }
    end
 end
end

